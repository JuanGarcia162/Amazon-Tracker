// Edge Function para enviar notificaciones push cuando un precio alcanza el objetivo
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PriceAlert {
  id: string
  user_id: string
  product_id: string
  target_price: number
  current_price: number
  notified: boolean
}

interface Product {
  id: string
  title: string
  image_url: string
  current_price: number
  url: string
}

interface FCMToken {
  fcm_token: string
  platform: string
}

// Función para obtener access token de Firebase usando Service Account
async function getFirebaseAccessToken(): Promise<string | null> {
  try {
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
    const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')
    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')

    if (!projectId || !privateKey || !clientEmail) {
      console.error('Firebase credentials not configured')
      return null
    }

    // Crear JWT para autenticación
    const header = {
      alg: 'RS256',
      typ: 'JWT',
    }

    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: clientEmail,
      sub: clientEmail,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
    }

    // Importar clave privada
    const pemKey = privateKey.replace(/\\n/g, '\n')
    const keyData = pemKey
      .replace('-----BEGIN PRIVATE KEY-----', '')
      .replace('-----END PRIVATE KEY-----', '')
      .replace(/\s/g, '')
    
    const binaryKey = Uint8Array.from(atob(keyData), c => c.charCodeAt(0))
    
    const cryptoKey = await crypto.subtle.importKey(
      'pkcs8',
      binaryKey,
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['sign']
    )

    // Crear JWT
    const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
    const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
    const unsignedToken = `${encodedHeader}.${encodedPayload}`
    
    const encoder = new TextEncoder()
    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      cryptoKey,
      encoder.encode(unsignedToken)
    )
    
    const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
    
    const jwt = `${unsignedToken}.${encodedSignature}`

    // Intercambiar JWT por access token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    })

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text()
      console.error('Token exchange error:', error)
      return null
    }

    const tokenData = await tokenResponse.json()
    return tokenData.access_token
  } catch (error) {
    console.error('Error getting Firebase access token:', error)
    return null
  }
}

// Función para enviar notificación push usando FCM v1 API
async function sendPushNotification(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  try {
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
    
    if (!projectId) {
      console.error('FIREBASE_PROJECT_ID not configured')
      return false
    }

    const accessToken = await getFirebaseAccessToken()
    
    if (!accessToken) {
      console.error('Failed to get Firebase access token')
      return false
    }

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: fcmToken,
            notification: {
              title,
              body,
            },
            data,
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
              },
            },
          },
        }),
      }
    )

    if (!response.ok) {
      const error = await response.text()
      console.error('FCM error:', error)
      return false
    }

    const result = await response.json()
    console.log('FCM response:', result)
    return true
  } catch (error) {
    console.error('Error sending push notification:', error)
    return false
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Crear cliente de Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Obtener alertas de precio no notificadas
    const { data: alerts, error: alertsError } = await supabase
      .from('price_alerts')
      .select('*')
      .eq('notified', false)
      .order('created_at', { ascending: true })
      .limit(100)

    if (alertsError) {
      throw alertsError
    }

    if (!alerts || alerts.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No pending alerts to send' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    console.log(`Processing ${alerts.length} price alerts...`)

    const results = {
      total: alerts.length,
      sent: 0,
      failed: 0,
    }

    // Procesar cada alerta
    for (const alert of alerts as PriceAlert[]) {
      try {
        // Obtener información del producto
        const { data: product, error: productError } = await supabase
          .from('products')
          .select('id, title, image_url, current_price, url')
          .eq('id', alert.product_id)
          .single()

        if (productError || !product) {
          console.error(`Product not found: ${alert.product_id}`)
          results.failed++
          continue
        }

        // Obtener FCM token del usuario
        const { data: tokenData, error: tokenError } = await supabase
          .from('user_fcm_tokens')
          .select('fcm_token, platform')
          .eq('user_id', alert.user_id)
          .single()

        if (tokenError || !tokenData) {
          console.error(`FCM token not found for user: ${alert.user_id}`)
          results.failed++
          
          // Marcar como notificada aunque no se envió (usuario sin token)
          await supabase
            .from('price_alerts')
            .update({ notified: true, notified_at: new Date().toISOString() })
            .eq('id', alert.id)
          
          continue
        }

        const productInfo = product as Product
        const fcmInfo = tokenData as FCMToken

        // Preparar mensaje de notificación
        const title = '🎉 ¡Precio Alcanzado!'
        const body = `${productInfo.title.substring(0, 80)}... ahora está a $${alert.current_price.toFixed(2)} (objetivo: $${alert.target_price.toFixed(2)})`
        
        const data = {
          product_id: alert.product_id,
          product_title: productInfo.title,
          current_price: alert.current_price.toString(),
          target_price: alert.target_price.toString(),
          product_url: productInfo.url,
          type: 'price_alert',
        }

        // Enviar notificación push
        const sent = await sendPushNotification(
          fcmInfo.fcm_token,
          title,
          body,
          data
        )

        if (sent) {
          console.log(`✅ Notification sent to user ${alert.user_id} for product ${alert.product_id}`)
          results.sent++
        } else {
          console.error(`❌ Failed to send notification to user ${alert.user_id}`)
          results.failed++
        }

        // Marcar alerta como notificada
        await supabase
          .from('price_alerts')
          .update({ 
            notified: true, 
            notified_at: new Date().toISOString() 
          })
          .eq('id', alert.id)

        // Pequeña pausa entre notificaciones
        await new Promise(resolve => setTimeout(resolve, 500))

      } catch (error) {
        console.error(`Error processing alert ${alert.id}:`, error)
        results.failed++
      }
    }

    console.log('Notification sending complete:', results)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Price alerts processed',
        results,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('Error in send-price-alert function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
