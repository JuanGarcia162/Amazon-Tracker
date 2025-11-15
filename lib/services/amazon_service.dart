import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/product.dart';

class AmazonService {
  static const String baseUrl = 'https://www.amazon.com';

  /// Optimize Amazon image URL for high resolution
  /// Amazon uses patterns like:
  /// - ._AC_SX300_.jpg (300px width)
  /// - ._AC_SL1500_.jpg (1500px)
  /// - ._SS40_.jpg (40px thumbnail)
  String _optimizeAmazonImageUrl(String url) {
    // Remove size constraints to get original/largest image
    // Common patterns to replace:
    var optimizedUrl = url;
    
    // Pattern 1: ._AC_SXnnn_ or ._AC_SYnnn_ (resize to specific dimension)
    optimizedUrl = optimizedUrl.replaceAll(RegExp(r'\._AC_S[XY]\d+_'), '');
    
    // Pattern 2: ._SSnnn_ (thumbnail size)
    optimizedUrl = optimizedUrl.replaceAll(RegExp(r'\._SS\d+_'), '');
    
    // Pattern 3: ._SLnnn_ (specific size)
    // Replace with larger size instead of removing
    optimizedUrl = optimizedUrl.replaceAll(RegExp(r'\._SL\d+_'), '._SL1500_');
    
    // Pattern 4: ._UXnnn_ or ._UYnnn_ (user experience size)
    optimizedUrl = optimizedUrl.replaceAll(RegExp(r'\._U[XY]\d+_'), '');
    
    // Pattern 5: ._CRn,n,n,n_ (crop parameters)
    optimizedUrl = optimizedUrl.replaceAll(RegExp(r'\._CR\d+,\d+,\d+,\d+_'), '');
    
    // If no size pattern was found, try to request larger version
    if (optimizedUrl == url && !optimizedUrl.contains('._SL')) {
      // Insert ._SL1500_ before the file extension
      optimizedUrl = optimizedUrl.replaceAll(RegExp(r'\.jpg$'), '._SL1500_.jpg');
      optimizedUrl = optimizedUrl.replaceAll(RegExp(r'\.png$'), '._SL1500_.png');
    }
    
    print('🖼️  Image URL optimized:');
    print('   Original: $url');
    print('   Optimized: $optimizedUrl');
    
    return optimizedUrl;
  }

  // Resolve short Amazon URLs (a.co) to full URLs
  Future<String> resolveShortUrl(String url) async {
    try {
      String currentUrl = url;
      int maxRedirects = 10; // Follow up to 10 redirects
      int redirectCount = 0;
      
      final client = http.Client();
      
      // Keep following redirects until we get a full amazon.com URL
      while ((currentUrl.contains('a.co') || currentUrl.contains('amzn.to')) && redirectCount < maxRedirects) {
        print('🔄 Following redirect #${redirectCount + 1}: $currentUrl');
        
        try {
          final request = http.Request('GET', Uri.parse(currentUrl));
          request.followRedirects = false; // We'll handle redirects manually
          request.headers.addAll({
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          });
          
          final streamedResponse = await client.send(request);
          final response = await http.Response.fromStream(streamedResponse);
          
          // Check for redirect status codes (301, 302, 303, 307, 308)
          if (response.statusCode >= 300 && response.statusCode < 400) {
            final location = response.headers['location'];
            if (location != null && location.isNotEmpty) {
              // Handle relative URLs
              if (location.startsWith('http')) {
                currentUrl = location;
              } else {
                final uri = Uri.parse(currentUrl);
                currentUrl = '${uri.scheme}://${uri.host}$location';
              }
              print('   → Redirecting to: $currentUrl');
            } else {
              print('   ⚠️ No location header found');
              break;
            }
          } else {
            // Not a redirect, check if we got the final URL from the request
            final finalUrl = streamedResponse.request?.url.toString() ?? currentUrl;
            if (finalUrl.contains('amazon.com')) {
              currentUrl = finalUrl;
              break;
            }
            break;
          }
        } catch (e) {
          print('   ⚠️ Error in redirect: $e');
          break;
        }
        
        redirectCount++;
        
        // If we reached a full amazon.com URL, stop
        if (currentUrl.contains('amazon.com')) {
          break;
        }
      }
      
      client.close();
      print('✅ Final resolved URL: $currentUrl');
      return currentUrl;
    } catch (e) {
      print('Error resolving short URL: $e');
      return url;
    }
  }

  // Extract ASIN from Amazon URL
  String? extractAsin(String url) {
    final patterns = [
      RegExp(r'/dp/([A-Z0-9]{10})'),
      RegExp(r'/gp/product/([A-Z0-9]{10})'),
      RegExp(r'ASIN=([A-Z0-9]{10})'),
      RegExp(r'/product/([A-Z0-9]{10})'),
      RegExp(r'/d/([A-Z0-9]{10})'), // For a.co/d/ short URLs
      RegExp(r'a\.co/d/([A-Z0-9]{7,10})'), // Alternative pattern for a.co
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  // Simulate fetching product data (in production, you'd need a proper API or web scraping with proper headers)
  Future<Product?> fetchProductData(String url) async {
    try {
      // Resolve short URLs first
      final resolvedUrl = await resolveShortUrl(url);
      
      final asin = extractAsin(resolvedUrl);
      if (asin == null) {
        throw Exception('Invalid Amazon URL');
      }

      // Note: Direct scraping Amazon requires proper headers and may be blocked
      // This is a simplified version. In production, consider using:
      // 1. Amazon Product Advertising API (requires approval)
      // 2. Third-party price tracking APIs
      // 3. Proper web scraping with rotating proxies and headers

      // IMPORTANT: Always use amazon.com (USD) to avoid currency conversion
      // Add session parameters to force USD pricing
      final productUrl = '$baseUrl/dp/$asin?language=en_US&currency=USD';
      
      final response = await http.get(
        Uri.parse(productUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          // Add cookies to force US region
          'Cookie': 'i18n-prefs=USD; lc-main=en_US; sp-cdn="L5Z9:CO"',
        },
      );
      
      print('🌐 Fetching from: $productUrl');

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);

        // Extract product title with multiple selectors
        String title = 'Producto de Amazon';
        
        final titleSelectors = [
          '#productTitle',
          '#title',
          'h1.product-title',
          'span#productTitle',
          '[data-feature-name="title"] h1',
        ];
        
        for (var selector in titleSelectors) {
          final titleElement = document.querySelector(selector);
          if (titleElement != null) {
            final extractedTitle = titleElement.text.trim();
            if (extractedTitle.isNotEmpty) {
              title = extractedTitle;
              break;
            }
          }
        }
        
        // If still no title, try to extract from meta tags
        if (title == 'Producto de Amazon') {
          final metaTitle = document.querySelector('meta[name="title"]')?.attributes['content'];
          if (metaTitle != null && metaTitle.isNotEmpty) {
            title = metaTitle.trim();
          }
        }

        // Extract currency symbol to ensure we're getting USD prices
        String currency = 'USD';
        final currencySymbol = document.querySelector('.a-price-symbol')?.text.trim() ?? '\$';
        
        // Extract current price
        final priceWhole =
            document.querySelector('.a-price-whole')?.text.trim() ?? '0';
        final priceFraction =
            document.querySelector('.a-price-fraction')?.text.trim() ?? '00';
        
        // Clean price parts (remove commas and dots from whole part)
        final cleanWhole = priceWhole.replaceAll(',', '').replaceAll('.', '');
        final cleanFraction = priceFraction.replaceAll(',', '').replaceAll('.', '');
        
        // Construct proper decimal price
        final priceString = '$cleanWhole.$cleanFraction';
        final currentPrice = double.tryParse(priceString) ?? 0.0;

        print('🔍 Price extraction:');
        print('   Whole: "$priceWhole" → "$cleanWhole"');
        print('   Fraction: "$priceFraction" → "$cleanFraction"');
        print('   Final: $currentPrice');

        // Detect if price is in wrong currency (COP, MXN, etc.)
        if (currencySymbol != '\$' || currentPrice > 100000) {
          print('⚠️  Warning: Non-USD currency detected');
          print('   Currency symbol: $currencySymbol');
          print('   Raw price: $currentPrice');
          print('   This appears to be in COP (Colombian Pesos) or another currency');
          print('   ');
          print('💡 SOLUCIÓN: Amazon está detectando tu ubicación en Colombia');
          print('   Opciones:');
          print('   1. Usa un VPN con ubicación en USA');
          print('   2. Usa la API oficial de Amazon Product Advertising');
          print('   3. Usa un servicio de scraping con proxies de USA');
          print('   ');
          throw Exception('Amazon está mostrando precios en $currencySymbol (no USD). Precio: $currentPrice. Usa VPN o cambia de región.');
        }

        if (currentPrice > 0 && currentPrice < 100000) {
          print('✅ Price extracted: \$$currentPrice USD');
        }

        // Extract original/list price (often shown as strikethrough or as "Precio recomendado")
        double originalPrice = currentPrice;
        
        // Try multiple selectors for original price
        final originalPriceSelectors = [
          '.a-price.a-text-price',           // Standard strikethrough price
          '.basisPrice .a-offscreen',        // Basis price (hidden text)
          '.a-text-strike',                  // Strikethrough text
          '[data-a-strike="true"]',          // Strike attribute
          '.priceBlockStrikePriceString',    // Old price block
          '.a-price[data-a-color="secondary"]', // Secondary price
        ];
        
        for (var selector in originalPriceSelectors) {
          final element = document.querySelector(selector);
          if (element != null) {
            final priceText = element.text.trim();
            print('🔍 Found original price candidate: "$priceText" (selector: $selector)');
            
            // Extract only numbers and decimal point
            final cleanPrice = priceText.replaceAll(RegExp(r'[^\d.]'), '');
            final parsedPrice = double.tryParse(cleanPrice);
            
            if (parsedPrice != null && parsedPrice > currentPrice) {
              originalPrice = parsedPrice;
              print('✅ Original price found: \$$originalPrice (was \$$currentPrice)');
              break;
            }
          }
        }
        
        // If no original price found, use current price
        if (originalPrice == currentPrice) {
          print('ℹ️  No discount found, using current price as original');
        } else {
          // Calculate and log discount
          final discountAmount = originalPrice - currentPrice;
          final discountPercent = ((discountAmount / originalPrice) * 100).round();
          print('💰 Discount: -$discountPercent% (Save \$${discountAmount.toStringAsFixed(2)})');
        }
        
        // Try to extract price history data from Amazon's price chart if available
        // Amazon sometimes includes this in script tags or data attributes
        List<PriceHistory> priceHistory = [];
        
        // Look for price history in page scripts
        final scripts = document.querySelectorAll('script');
        double? minHistoricalPrice;
        double? maxHistoricalPrice;
        
        for (var script in scripts) {
          final scriptContent = script.text;
          
          // Try to find lowest price mention
          final lowestPriceMatch = RegExp(r'lowest["\s:]+\$?([\d,]+\.?\d*)').firstMatch(scriptContent);
          if (lowestPriceMatch != null) {
            minHistoricalPrice = double.tryParse(lowestPriceMatch.group(1)?.replaceAll(',', '') ?? '');
          }
          
          // Try to find highest price mention
          final highestPriceMatch = RegExp(r'highest["\s:]+\$?([\d,]+\.?\d*)').firstMatch(scriptContent);
          if (highestPriceMatch != null) {
            maxHistoricalPrice = double.tryParse(highestPriceMatch.group(1)?.replaceAll(',', '') ?? '');
          }
        }
        
        // If we found historical prices, create history entries
        final now = DateTime.now();
        final productId = DateTime.now().millisecondsSinceEpoch.toString();
        
        if (minHistoricalPrice != null && minHistoricalPrice != currentPrice) {
          priceHistory.add(PriceHistory(
            id: '${productId}_min',
            productId: productId,
            price: minHistoricalPrice,
            timestamp: now.subtract(const Duration(days: 30)), // Estimate 30 days ago
          ));
        }
        
        if (maxHistoricalPrice != null && maxHistoricalPrice != currentPrice) {
          priceHistory.add(PriceHistory(
            id: '${productId}_max',
            productId: productId,
            price: maxHistoricalPrice,
            timestamp: now.subtract(const Duration(days: 60)), // Estimate 60 days ago
          ));
        }
        
        // Always add current price
        priceHistory.add(PriceHistory(
          id: '${productId}_current',
          productId: productId,
          price: currentPrice,
          timestamp: now,
        ));

        // Try multiple selectors for product image
        String imageUrl = 'https://via.placeholder.com/300x300.png?text=No+Image';
        
        // Try different image selectors (prioritize high-res sources)
        final imageSelectors = [
          '#landingImage',
          '#imgBlkFront',
          '#main-image',
          '.a-dynamic-image',
          'img[data-a-dynamic-image]',
        ];
        
        for (var selector in imageSelectors) {
          final imgElement = document.querySelector(selector);
          if (imgElement != null) {
            String? src;
            
            // Priority 1: data-old-hires (highest resolution)
            src = imgElement.attributes['data-old-hires'];
            
            // Priority 2: data-a-dynamic-image (contains multiple resolutions)
            if (src == null || src.isEmpty) {
              final dynamicImage = imgElement.attributes['data-a-dynamic-image'];
              if (dynamicImage != null && dynamicImage.isNotEmpty) {
                // Parse JSON to get the LARGEST image URL
                try {
                  // Extract all URLs with their dimensions
                  final regex = RegExp(r'"(https://[^"]+)"\s*:\s*\[(\d+),(\d+)\]');
                  final matches = regex.allMatches(dynamicImage);
                  
                  String? largestUrl;
                  int maxPixels = 0;
                  
                  for (var match in matches) {
                    final url = match.group(1);
                    final width = int.tryParse(match.group(2) ?? '0') ?? 0;
                    final height = int.tryParse(match.group(3) ?? '0') ?? 0;
                    final pixels = width * height;
                    
                    if (pixels > maxPixels && url != null) {
                      maxPixels = pixels;
                      largestUrl = url;
                    }
                  }
                  
                  if (largestUrl != null) {
                    src = largestUrl;
                  }
                } catch (e) {
                  print('Error parsing dynamic image: $e');
                }
              }
            }
            
            // Priority 3: Regular src attribute
            src ??= imgElement.attributes['src'];
            
            // Clean and optimize the URL for high resolution
            if (src != null && src.isNotEmpty && src.startsWith('http')) {
              // Amazon image URLs often have size parameters like ._AC_SX300_.jpg
              // Replace with larger size or remove size constraints
              imageUrl = _optimizeAmazonImageUrl(src);
              break;
            }
          }
        }

        return Product(
          id: productId,
          asin: asin,
          title: title,
          imageUrl: imageUrl,
          currentPrice: currentPrice,
          originalPrice: originalPrice,
          currency: currency, // Always USD
          url: url,
          lastUpdated: DateTime.now(),
          priceHistory: priceHistory,
        );
      } else {
        throw Exception('Failed to fetch product data');
      }
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }
}
