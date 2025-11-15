import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Product {
  id: string
  user_id: string
  url: string
  current_price: number
  target_price: number | null
  title: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('🔄 Iniciando actualización de precios para todos los productos...')

    // Crear cliente de Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Obtener todos los productos activos
    const { data: products, error: productsError } = await supabase
      .from('products')
      .select('id, user_id, url, current_price, target_price, title')
      .order('last_updated', { ascending: true })
      .limit(50) // Procesar 50 productos por ejecución

    if (productsError) {
      throw new Error(`Error obteniendo productos: ${productsError.message}`)
    }

    if (!products || products.length === 0) {
      console.log('ℹ️ No hay productos para actualizar')
      return new Response(
        JSON.stringify({ message: 'No hay productos para actualizar', updated: 0 }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`📦 Procesando ${products.length} productos...`)

    let updatedCount = 0
    let alertsCreated = 0

    // Procesar productos uno por uno con delay para evitar rate limiting
    for (const product of products) {
      try {
        console.log(`🔍 Procesando: ${product.title}`)

        // Hacer scraping del precio
        const newPrice = await scrapeAmazonPrice(product.url)

        if (newPrice === null) {
          console.log(`⚠️ No se pudo obtener precio para: ${product.title}`)
          continue
        }

        // Actualizar precio en la base de datos
        const { error: updateError } = await supabase
          .from('products')
          .update({
            current_price: newPrice,
            last_updated: new Date().toISOString(),
          })
          .eq('id', product.id)

        if (updateError) {
          console.error(`❌ Error actualizando producto ${product.id}:`, updateError)
          continue
        }

        // Guardar en historial
        await supabase.from('price_history').insert({
          product_id: product.id,
          price: newPrice,
          recorded_at: new Date().toISOString(),
        })

        updatedCount++
        console.log(`✅ Actualizado: ${product.title} - $${newPrice}`)

        // Verificar si se alcanzó el precio objetivo
        if (product.target_price && newPrice <= product.target_price) {
          // Verificar si ya existe una alerta reciente (últimas 24 horas)
          const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
          
          const { data: recentAlerts } = await supabase
            .from('price_alerts')
            .select('id')
            .eq('product_id', product.id)
            .eq('user_id', product.user_id)
            .gte('created_at', twentyFourHoursAgo)

          if (!recentAlerts || recentAlerts.length === 0) {
            // Crear alerta
            await supabase.from('price_alerts').insert({
              product_id: product.id,
              user_id: product.user_id,
              target_price: product.target_price,
              current_price: newPrice,
              notified: false,
            })

            alertsCreated++
            console.log(`🔔 Alerta creada para: ${product.title}`)

            // Enviar notificación
            try {
              await supabase.functions.invoke('send-price-alert', {
                body: { productId: product.id },
              })
              console.log(`📬 Notificación enviada para: ${product.title}`)
            } catch (notifError) {
              console.error(`❌ Error enviando notificación:`, notifError)
            }
          }
        }

        // Delay entre requests para evitar rate limiting (2-5 segundos aleatorio)
        const delay = 2000 + Math.random() * 3000
        await new Promise(resolve => setTimeout(resolve, delay))

      } catch (error) {
        console.error(`❌ Error procesando producto ${product.id}:`, error)
        continue
      }
    }

    const result = {
      message: 'Actualización completada',
      processed: products.length,
      updated: updatedCount,
      alerts_created: alertsCreated,
      timestamp: new Date().toISOString(),
    }

    console.log('✅ Actualización completada:', result)

    return new Response(
      JSON.stringify(result),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('❌ Error en refresh-all-prices:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

/**
 * Scraping de Amazon con técnicas anti-detección
 */
async function scrapeAmazonPrice(url: string): Promise<number | null> {
  try {
    // Headers realistas para evitar detección
    const headers = {
      'User-Agent': getRandomUserAgent(),
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Cache-Control': 'max-age=0',
    }

    // Hacer request con delay aleatorio
    await new Promise(resolve => setTimeout(resolve, Math.random() * 1000))

    const response = await fetch(url, {
      headers,
      redirect: 'follow',
    })

    if (!response.ok) {
      console.error(`HTTP error: ${response.status}`)
      return null
    }

    const html = await response.text()

    // Múltiples selectores para encontrar el precio
    const pricePatterns = [
      // Precio principal
      /<span class="a-price-whole">([0-9,]+)<\/span>/,
      /<span class="a-offscreen">\$([0-9,]+\.[0-9]{2})<\/span>/,
      // Precio de oferta
      /<span class="priceToPay.*?>\$([0-9,]+\.[0-9]{2})<\/span>/,
      // Precio en deals
      /<span class="a-price.*?>\$([0-9,]+\.[0-9]{2})<\/span>/,
      // Formato alternativo
      /priceblock_ourprice.*?>\$([0-9,]+\.[0-9]{2})</,
    ]

    for (const pattern of pricePatterns) {
      const match = html.match(pattern)
      if (match && match[1]) {
        const priceStr = match[1].replace(/,/g, '')
        const price = parseFloat(priceStr)
        if (!isNaN(price) && price > 0) {
          return price
        }
      }
    }

    console.error('No se pudo extraer el precio del HTML')
    return null

  } catch (error) {
    console.error('Error en scraping:', error)
    return null
  }
}

/**
 * Obtener User-Agent aleatorio para evitar detección
 */
function getRandomUserAgent(): string {
  const userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  ]
  return userAgents[Math.floor(Math.random() * userAgents.length)]
}
