import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ProductData {
  title: string
  currentPrice: number
  originalPrice?: number
  imageUrl: string
  asin: string
  url: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { url, targetPrice } = await req.json()
    
    if (!url) {
      return new Response(
        JSON.stringify({ error: 'URL is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`🔍 Adding product from URL: ${url}`)

    // Crear cliente de Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Extraer ASIN de la URL
    const asin = extractAsin(url)
    if (!asin) {
      return new Response(
        JSON.stringify({ error: 'Invalid Amazon URL' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`📦 ASIN extracted: ${asin}`)

    // Verificar si el producto ya existe
    const { data: existingProduct } = await supabase
      .from('products')
      .select('*')
      .eq('asin', asin)
      .single()

    if (existingProduct) {
      console.log(`✅ Product already exists: ${existingProduct.title}`)
      
      // Obtener user_id del token
      const authHeader = req.headers.get('Authorization')
      if (!authHeader) {
        return new Response(
          JSON.stringify({ error: 'Authorization required' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      const token = authHeader.replace('Bearer ', '')
      const { data: { user } } = await supabase.auth.getUser(token)
      
      if (!user) {
        return new Response(
          JSON.stringify({ error: 'Invalid token' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Agregar a favoritos del usuario
      await supabase
        .from('user_favorites')
        .upsert({
          user_id: user.id,
          product_id: existingProduct.id,
          target_price: targetPrice,
        })

      return new Response(
        JSON.stringify({
          success: true,
          product: existingProduct,
          message: 'Product added to favorites',
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Scrapear datos del producto
    const productData = await scrapeAmazonProduct(asin)
    
    if (!productData) {
      return new Response(
        JSON.stringify({ error: 'Could not fetch product data from Amazon' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`✅ Product data scraped: ${productData.title}`)

    // Insertar producto en la base de datos
    const { data: newProduct, error: insertError } = await supabase
      .from('products')
      .insert({
        asin: productData.asin,
        title: productData.title,
        url: productData.url,
        current_price: productData.currentPrice,
        original_price: productData.originalPrice || productData.currentPrice,
        image_url: productData.imageUrl,
        currency: 'USD',
        last_updated: new Date().toISOString(),
      })
      .select()
      .single()

    if (insertError) {
      console.error('Error inserting product:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to save product' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Insertar precio inicial en historial
    await supabase
      .from('price_history')
      .insert({
        product_id: newProduct.id,
        price: productData.currentPrice,
        timestamp: new Date().toISOString(),
      })

    // Obtener user_id del token y agregar a favoritos
    const authHeader = req.headers.get('Authorization')
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '')
      const { data: { user } } = await supabase.auth.getUser(token)
      
      if (user) {
        await supabase
          .from('user_favorites')
          .insert({
            user_id: user.id,
            product_id: newProduct.id,
            target_price: targetPrice,
          })
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        product: newProduct,
        message: 'Product added successfully',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in add-product function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function extractAsin(url: string): string | null {
  const asinMatch = url.match(/\/dp\/([A-Z0-9]{10})/)
  return asinMatch ? asinMatch[1] : null
}

async function scrapeAmazonProduct(asin: string): Promise<ProductData | null> {
  try {
    const userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    ]
    const randomUA = userAgents[Math.floor(Math.random() * userAgents.length)]

    const url = `https://www.amazon.com/dp/${asin}?language=en_US&currency=USD`
    
    // Delay aleatorio antes del request
    await new Promise(resolve => setTimeout(resolve, Math.random() * 1000))

    const response = await fetch(url, {
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
        'Cookie': 'i18n-prefs=USD; lc-main=en_US; sp-cdn="L5Z9:CO"; session-id=' + Math.random().toString(36).substring(7),
      },
    })

    if (!response.ok) {
      console.error(`HTTP Error: ${response.status}`)
      return null
    }

    const html = await response.text()

    // Extraer título
    let title = 'Producto de Amazon'
    const titleMatch = html.match(/<span id="productTitle"[^>]*>([^<]+)<\/span>/)
    if (titleMatch) {
      title = titleMatch[1].trim()
    }

    // Extraer precio
    const priceWholeMatch = html.match(/<span class="a-price-whole">([^<]+)<\/span>/)
    const priceFractionMatch = html.match(/<span class="a-price-fraction">([^<]+)<\/span>/)
    
    let currentPrice = 0
    if (priceWholeMatch) {
      const whole = priceWholeMatch[1].trim().replaceAll(',', '').replaceAll('.', '')
      const fraction = priceFractionMatch ? priceFractionMatch[1].trim() : '00'
      currentPrice = parseFloat(`${whole}.${fraction}`)
    }

    // Extraer imagen
    let imageUrl = ''
    const imageMatch = html.match(/"hiRes":"([^"]+)"/) || html.match(/"large":"([^"]+)"/)
    if (imageMatch) {
      imageUrl = imageMatch[1]
    }

    // Si no se encontró imagen de alta resolución, buscar la imagen principal
    if (!imageUrl) {
      const mainImageMatch = html.match(/<img[^>]+id="landingImage"[^>]+src="([^"]+)"/)
      if (mainImageMatch) {
        imageUrl = mainImageMatch[1]
      }
    }

    console.log(`📦 Scraped data:`)
    console.log(`   Title: ${title}`)
    console.log(`   Price: $${currentPrice}`)
    console.log(`   Image: ${imageUrl ? 'Found' : 'Not found'}`)

    if (currentPrice === 0 || !imageUrl) {
      console.error('Failed to extract required data')
      return null
    }

    return {
      title,
      currentPrice,
      originalPrice: currentPrice,
      imageUrl,
      asin,
      url: `https://www.amazon.com/dp/${asin}`,
    }
  } catch (error) {
    console.error('Error scraping product:', error)
    return null
  }
}
