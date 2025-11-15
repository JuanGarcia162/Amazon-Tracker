// Edge Function para actualizar precios de productos automáticamente
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Product {
  id: string
  asin: string
  title: string
  url: string
  current_price: number
  currency: string
}

interface PriceData {
  price: number
  originalPrice?: number
  currency: string
}

// Función para limpiar URL de Amazon (quitar parámetros innecesarios)
function cleanAmazonUrl(url: string): string {
  try {
    // Extraer ASIN de la URL
    const asinMatch = url.match(/\/dp\/([A-Z0-9]{10})/)
    if (asinMatch) {
      return `https://www.amazon.com/dp/${asinMatch[1]}`
    }
    return url
  } catch {
    return url
  }
}

// Función para extraer precio de Amazon mediante scraping
async function fetchAmazonPrice(url: string): Promise<PriceData | null> {
  try {
    // Limpiar URL para evitar problemas con parámetros
    const cleanUrl = cleanAmazonUrl(url)
    console.log(`   📡 Fetching URL: ${cleanUrl}`)
    
    // Rotar User-Agents para parecer más humano (más variedad)
    const userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    ]
    const randomUA = userAgents[Math.floor(Math.random() * userAgents.length)]
    
    // Agregar parámetros de URL para forzar USD (como en Flutter)
    const urlWithParams = cleanUrl.includes('?') 
      ? `${cleanUrl}&language=en_US&currency=USD`
      : `${cleanUrl}?language=en_US&currency=USD`
    
    // Delay aleatorio antes del request (simular comportamiento humano)
    await new Promise(resolve => setTimeout(resolve, Math.random() * 1000))
    
    const response = await fetch(urlWithParams, {
      headers: {
        'User-Agent': randomUA,
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
        // Cookies más completas para parecer usuario real
        'Cookie': 'i18n-prefs=USD; lc-main=en_US; sp-cdn="L5Z9:CO"; session-id=' + Math.random().toString(36).substring(7),
      },
    })

    if (!response.ok) {
      console.error(`   ❌ HTTP Error: ${response.status} ${response.statusText}`)
      return null
    }
    
    console.log(`   ✅ Response received, parsing HTML...`)

    const html = await response.text()

    // Método 1: Buscar .a-price-whole y .a-price-fraction (como en Flutter)
    let price: number | null = null
    
    // Buscar precio whole
    const priceWholeMatch = html.match(/<span class="a-price-whole">([^<]+)<\/span>/)
    const priceFractionMatch = html.match(/<span class="a-price-fraction">([^<]+)<\/span>/)
    
    if (priceWholeMatch) {
      const whole = priceWholeMatch[1].trim().replaceAll(',', '').replaceAll('.', '')
      const fraction = priceFractionMatch ? priceFractionMatch[1].trim().replaceAll(',', '').replaceAll('.', '') : '00'
      
      const priceString = `${whole}.${fraction}`
      price = parseFloat(priceString)
      
      if (!isNaN(price) && price > 0) {
        console.log(`   💰 Price extracted: $${price} (whole: ${whole}, fraction: ${fraction})`)
      } else {
        price = null
      }
    }
    
    // Método 2: Si no funcionó, intentar con a-offscreen
    if (!price) {
      const offscreenMatch = html.match(/<span class="a-offscreen">\$([0-9,]+\.?[0-9]*)<\/span>/)
      if (offscreenMatch) {
        const priceStr = offscreenMatch[1].replace(/,/g, '')
        price = parseFloat(priceStr)
        if (!isNaN(price) && price > 0) {
          console.log(`   💰 Price extracted: $${price} (from a-offscreen)`)
        } else {
          price = null
        }
      }
    }

    if (!price) {
      console.error(`   ❌ Could not extract price from HTML`)
      
      // Debug: Buscar elementos de precio en el HTML
      const wholePrices = html.match(/<span class="a-price-whole">[^<]+<\/span>/g)
      const fractionPrices = html.match(/<span class="a-price-fraction">[^<]+<\/span>/g)
      const offscreenPrices = html.match(/<span class="a-offscreen">[^<]+<\/span>/g)
      
      console.log(`   🔍 Debug info:`)
      console.log(`      a-price-whole found: ${wholePrices ? wholePrices.length : 0}`)
      console.log(`      a-price-fraction found: ${fractionPrices ? fractionPrices.length : 0}`)
      console.log(`      a-offscreen found: ${offscreenPrices ? offscreenPrices.length : 0}`)
      
      if (wholePrices && wholePrices.length > 0) {
        console.log(`      First whole: ${wholePrices[0]}`)
      }
      if (offscreenPrices && offscreenPrices.length > 0) {
        console.log(`      First offscreen: ${offscreenPrices[0]}`)
      }
      
      return null
    }

    // Intentar extraer precio original (tachado)
    const originalPricePatterns = [
      /<span class="a-price a-text-price"[^>]*>\s*<span class="a-offscreen">\$([0-9,.]+)<\/span>/,
      /<span class="a-text-strike"[^>]*>\$([0-9,.]+)<\/span>/,
    ]

    let originalPrice: number | undefined
    for (const pattern of originalPricePatterns) {
      const match = html.match(pattern)
      if (match) {
        const priceStr = match[1].replace(/,/g, '')
        const parsedPrice = parseFloat(priceStr)
        if (!isNaN(parsedPrice) && parsedPrice > price) {
          originalPrice = parsedPrice
          break
        }
      }
    }

    return {
      price,
      originalPrice,
      currency: 'USD',
    }
  } catch (error) {
    console.error(`Error fetching price for ${url}:`, error)
    return null
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

    // Obtener todos los productos
    const { data: products, error: productsError } = await supabase
      .from('products')
      .select('id, asin, title, url, current_price, currency')
      .order('last_updated', { ascending: true })
      .limit(50) // Procesar 50 productos por ejecución

    if (productsError) {
      throw productsError
    }

    if (!products || products.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No products to update' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    console.log(`Processing ${products.length} products...`)

    const results = {
      total: products.length,
      updated: 0,
      unchanged: 0,
      errors: 0,
      notifications: 0,
    }

    // Procesar cada producto
    for (let i = 0; i < (products as Product[]).length; i++) {
      const product = (products as Product[])[i]
      
      try {
        console.log(`\n🔍 [${i + 1}/${products.length}] Checking price for: ${product.title}`)
        console.log(`   URL: ${product.url}`)
        
        // Delay aleatorio ANTES de hacer el request (1-3 segundos)
        const preDelay = 1000 + Math.random() * 2000
        await new Promise(resolve => setTimeout(resolve, preDelay))
        
        const priceData = await fetchAmazonPrice(product.url)
        
        if (!priceData) {
          console.error(`❌ Failed to fetch price for ${product.title}`)
          console.error(`   URL was: ${product.url}`)
          results.errors++
          
          // Delay más largo si falla (posible rate limit) - 5-8 segundos aleatorio
          if (i < products.length - 1) {
            const errorDelay = 5000 + Math.random() * 3000
            console.log(`   ⏳ Waiting ${Math.round(errorDelay/1000)} seconds before next request...`)
            await new Promise(resolve => setTimeout(resolve, errorDelay))
          }
          continue
        }
        
        console.log(`✅ Fetched price: $${priceData.price} (original: $${priceData.originalPrice})`)
        
        // Delay aleatorio entre requests (2-5 segundos)
        if (i < products.length - 1) {
          const delay = 2000 + Math.random() * 3000
          console.log(`   ⏳ Waiting ${Math.round(delay/1000)} seconds before next request...`)
          await new Promise(resolve => setTimeout(resolve, delay))
        }

        // Verificar si el precio cambió
        if (Math.abs(priceData.price - product.current_price) < 0.01) {
          console.log(`Price unchanged for ${product.title}: $${priceData.price}`)
          results.unchanged++
          
          // Actualizar last_updated aunque no haya cambio
          await supabase
            .from('products')
            .update({ last_updated: new Date().toISOString() })
            .eq('id', product.id)
          
          continue
        }

        console.log(`Price changed for ${product.title}: $${product.current_price} → $${priceData.price}`)

        // Actualizar precio del producto
        const { error: updateError } = await supabase
          .from('products')
          .update({
            current_price: priceData.price,
            original_price: priceData.originalPrice,
            last_updated: new Date().toISOString(),
          })
          .eq('id', product.id)

        if (updateError) {
          console.error(`Error updating product ${product.id}:`, updateError)
          results.errors++
          continue
        }

        // Agregar entrada al historial de precios
        const { error: historyError } = await supabase
          .from('price_history')
          .insert({
            id: `${product.id}_${Date.now()}`,
            product_id: product.id,
            price: priceData.price,
            timestamp: new Date().toISOString(),
          })

        if (historyError) {
          console.error(`Error inserting price history for ${product.id}:`, historyError)
        }

        results.updated++

        // Verificar si hay usuarios con precio objetivo alcanzado
        const { data: favorites, error: favError } = await supabase
          .from('user_favorites')
          .select('user_id, target_price')
          .eq('product_id', product.id)
          .not('target_price', 'is', null)

        if (!favError && favorites && favorites.length > 0) {
          for (const favorite of favorites) {
            // Si el nuevo precio es menor o igual al precio objetivo
            if (priceData.price <= favorite.target_price) {
              console.log(`Target price reached for user ${favorite.user_id}!`)
              
              // Aquí se enviará la notificación push (implementaremos en el siguiente paso)
              // Por ahora, solo registramos el evento
              await supabase
                .from('price_alerts')
                .insert({
                  user_id: favorite.user_id,
                  product_id: product.id,
                  target_price: favorite.target_price,
                  current_price: priceData.price,
                  created_at: new Date().toISOString(),
                })
                .select()
                .single()
              
              results.notifications++
            }
          }
        }

      } catch (error) {
        console.error(`Error processing product ${product.id}:`, error)
        results.errors++
      }
    }

    console.log('Update complete:', results)

    // Si hay notificaciones pendientes, llamar a la función de envío
    if (results.notifications > 0) {
      console.log(`📬 Triggering send-price-alert function for ${results.notifications} alerts...`)
      
      try {
        const alertResponse = await fetch(`${supabaseUrl}/functions/v1/send-price-alert`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${supabaseServiceKey}`,
            'Content-Type': 'application/json',
          },
        })
        
        if (alertResponse.ok) {
          const alertResult = await alertResponse.json()
          console.log('✅ Alert notifications sent:', alertResult)
        } else {
          console.error('❌ Failed to send alert notifications')
        }
      } catch (error) {
        console.error('Error calling send-price-alert:', error)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Price update completed',
        results,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('Error in refresh-prices function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
