# 🛍️ Amazon Tracker

Una aplicación móvil para rastrear precios de productos de Amazon US, diseñada específicamente para dispositivos Apple con **diseño nativo de iOS**.

## ✨ Características

- **Diseño Nativo iOS**: Interfaz completamente rediseñada con Cupertino widgets
- **Navegación por Tabs**: CupertinoTabBar con 3 secciones (Todos, Ofertas, Alertas)
- **Seguimiento de Precios**: Monitorea automáticamente los precios de productos de Amazon
- **Gráficos Interactivos**: Visualiza historial con CupertinoSegmentedControl
- **Alertas de Precio**: Establece un precio objetivo con diálogos nativos iOS
- **Detección de Descuentos**: Identifica automáticamente productos con descuento
- **Soporte para URLs Cortas**: Compatible con enlaces amazon.com y a.co
- **Base de Datos Local**: Almacenamiento persistente con SQLite
- **Tipografía SF Pro**: Fuentes nativas de iOS para una experiencia auténtica
- **Pull to Refresh**: Actualización de precios con gesto nativo iOS
- **Modo Claro/Oscuro**: Adaptación automática al tema del sistema
- **Extracción Mejorada de Imágenes**: Múltiples métodos para obtener imágenes de alta calidad

## 🚀 Instalación

### Requisitos Previos

- Flutter SDK (3.9.2 o superior)
- Xcode (para desarrollo iOS)
- Cuenta de desarrollador de Apple (para deployment)
- CocoaPods

### Pasos de Instalación

1. Clona el repositorio:
   ```bash
   git clone <repository-url>
   cd amazon_tracker
   ```

2. Instala las dependencias:
   ```bash
   flutter pub get
   ```

3. Instala pods de iOS (para dispositivos Apple):
   ```bash
   cd ios
   pod install
   cd ..
   ```

5. Ejecuta la aplicación:
   ```bash
   flutter run
   ```
   

   O para un dispositivo específico:
   ```bash
   flutter run -d <device-id>
   ```

## 📖 Cómo Usar

### Agregar un Producto

1. Toca el botón **"+ Agregar"** en la pantalla principal
2. Copia la URL del producto desde Amazon US
   - Formato largo: `https://www.amazon.com/dp/B08N5WRWNW`
   - Formato corto: `https://a.co/d/73v020J` ✅
3. Pega la URL en el campo correspondiente
4. (Opcional) Establece un precio objetivo para recibir alertas
5. Toca **"Agregar Producto"**

### Monitorear Precios

- **Vista "Todos"**: Muestra todos los productos rastreados
- **Vista "Ofertas"**: Filtra productos con descuentos activos
- **Vista "Alertas"**: Muestra productos que alcanzaron su precio objetivo

### Ver Detalles del Producto

1. Toca cualquier tarjeta de producto
2. Visualiza el historial de precios en gráfico interactivo
3. **Selecciona la temporalidad**: 3 días, 7 días, 20 días o Todo
4. **Toca cualquier punto** del gráfico para ver precio y fecha exactos
5. Visualiza estadísticas: Precio Actual, Mínimo, Máximo y Promedio
6. Edita el precio objetivo (se muestra como línea naranja en el gráfico)
7. Abre el producto directamente en Amazon
8. Elimina el producto del rastreo

**Nota**: El historial de precios se construye con datos reales de Amazon. Cada vez que actualices los precios, se agregará un nuevo punto al historial.

### Actualizar Precios

- Desliza hacia abajo en la lista para actualizar manualmente
- Toca el ícono de actualización en la barra superior

## 🏗️ Arquitectura

```
lib/
├── models/           # Modelos de datos (Product, PriceHistory)
├── providers/        # Gestión de estado con Provider
├── screens/          # Pantallas de la aplicación
│   ├── home_screen.dart
│   ├── add_product_screen.dart
│   └── product_detail_screen.dart
├── services/         # Servicios (Database, Amazon API)
│   ├── database_service.dart
│   └── amazon_service.dart
├── widgets/          # Componentes reutilizables
│   └── product_card.dart
└── main.dart         # Punto de entrada
```

## 📦 Dependencias Principales

- **provider**: Gestión de estado
- **sqflite**: Base de datos local SQLite
- **fl_chart**: Gráficos de historial de precios
- **http**: Peticiones HTTP para obtener datos de productos
- **url_launcher**: Abrir enlaces de Amazon
- **shared_preferences**: Almacenamiento de preferencias
- **intl**: Formateo de moneda y fechas

## 🔧 Obtención de Datos de Amazon

Esta aplicación utiliza **scraping directo** de Amazon para obtener datos de productos:

### ✨ Características:

- **100% Gratuito** - Sin necesidad de APIs de pago
- **Datos en tiempo real** - Precios actuales directamente de Amazon
- **Extracción inteligente** - Múltiples métodos para obtener datos
- **Historial de precios** - Detecta precios mínimos y máximos históricos
- **Soporte de URLs** - Funciona con URLs completas y cortas

### 📊 Datos Extraídos:

- ✅ **Título del producto**
- ✅ **Precio actual**
- ✅ **Precio original** (si hay descuento)
- ✅ **Imágenes del producto**
- ✅ **ASIN** (identificador único)
- ✅ **Precios históricos** (min/max de scripts de Amazon)

### ⚠️ Limitaciones:

- Amazon puede bloquear solicitudes excesivas
- Algunos productos pueden no tener todos los datos
- Recomendado: No actualizar más de 10 productos simultáneamente

## 🎨 Personalización

### Cambiar el Color del Tema

Edita `lib/main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFFFF9900), // Cambia este color
  brightness: Brightness.light,
),
```

## 📱 Compatibilidad

- ✅ iOS 12.0+
- ✅ iPhone y iPad
- ✅ Modo claro y oscuro
- ✅ Orientación vertical y horizontal

## 🔮 Próximas Características

- [ ] Notificaciones push cuando el precio baje
- [ ] Compartir productos con amigos
- [ ] Exportar historial de precios
- [ ] Soporte para múltiples regiones de Amazon
- [ ] Widget de iOS para precios rápidos

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request para sugerencias y mejoras.
