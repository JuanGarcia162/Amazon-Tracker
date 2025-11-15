# 🛍️ Amazon Tracker

Una aplicación móvil completa para rastrear precios de productos de Amazon US, con **diseño nativo de iOS** y sincronización en la nube mediante Supabase.

## ✨ Características Principales

### 🎯 Gestión de Productos
- **Explorar Productos**: Descubre productos agregados por otros usuarios
- **Favoritos con Colecciones**: Organiza tus productos en colecciones personalizadas
- **Búsqueda Inteligente**: Busca productos por nombre en Explorar, Favoritos y Ofertas
- **Agregar a Favoritos**: Guarda productos de otros usuarios con un solo tap

### 📊 Seguimiento de Precios
- **Gráficos Interactivos**: Visualiza historial de precios con múltiples temporalidades
- **Precio Objetivo**: Establece alertas cuando el precio alcance tu meta
- **Detección de Descuentos**: Identifica automáticamente productos con descuento
- **Historial Completo**: Rastrea precios mínimos, máximos y promedio

### 🔔 Notificaciones
- **Push Notifications**: Recibe alertas cuando el precio baje (Firebase Cloud Messaging)
- **Notificaciones In-App**: Alertas visuales dentro de la aplicación
- **Alertas Personalizadas**: Configura precios objetivo individuales

### ☁️ Sincronización y Colaboración
- **Supabase Backend**: Base de datos compartida en tiempo real
- **Realtime Updates**: Cambios sincronizados automáticamente entre dispositivos
- **Productos Compartidos**: Explora y guarda productos de otros usuarios
- **Edge Functions**: Actualización automática de precios con cron jobs

### 🎨 Diseño y UX
- **Diseño Nativo iOS**: Interfaz con Cupertino widgets
- **5 Pestañas**: Explorar, Favoritos, Ofertas, Alertas, Ajustes
- **Modo Claro/Oscuro**: Adaptación automática al tema del sistema
- **Pull to Refresh**: Actualización de precios con gesto nativo
- **Animaciones Fluidas**: Transiciones suaves y naturales

## 🚀 Instalación

### Requisitos Previos

- Flutter SDK (3.9.2 o superior)
- Xcode (para desarrollo iOS)
- Cuenta de desarrollador de Apple (para deployment)
- CocoaPods

### Pasos de Instalación

1. **Clona el repositorio**:
   ```bash
   git clone git@github.com:JuanGarcia162/Amazon-Tracker.git
   cd amazon_tracker
   ```

2. **Instala las dependencias**:
   ```bash
   flutter pub get
   ```

3. **Configura Supabase**:
   - Crea un proyecto en [Supabase](https://supabase.com)
   - Ejecuta el schema SQL ubicado en `supabase_schema.sql`
   - Configura las credenciales en tu proyecto

4. **Configura Firebase** (para notificaciones):
   - Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
   - Descarga `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
   - Colócalos en las carpetas correspondientes

5. **Instala pods de iOS**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

6. **Ejecuta la aplicación**:
   ```bash
   flutter run
   ```

## 📖 Cómo Usar

### 🔍 Explorar Productos

1. Ve a la pestaña **"Explorar"**
2. Navega por productos agregados por otros usuarios
3. Usa la **barra de búsqueda** para encontrar productos específicos
4. Toca el **corazón** en cualquier producto para agregarlo a tus favoritos
5. Toca un producto para ver sus detalles completos

### ⭐ Gestionar Favoritos

1. Ve a la pestaña **"Favoritos"**
2. Usa la **barra de búsqueda** para filtrar tus productos
3. Organiza con **colecciones**:
   - **Todos**: Ver todos tus favoritos
   - **Sin categoría**: Productos sin asignar
   - **Colecciones personalizadas**: Crea y gestiona tus propias colecciones
4. Toca el botón **"+"** para agregar un nuevo producto desde Amazon

### ➕ Agregar un Producto Nuevo

1. Toca el botón **"+"** en Favoritos
2. Copia la URL del producto desde Amazon US:
   - Formato largo: `https://www.amazon.com/dp/B08N5WRWNW`
   - Formato corto: `https://a.co/d/73v020J` ✅
3. Pega la URL en el campo correspondiente
4. (Opcional) Establece un **precio objetivo** para recibir alertas
5. Toca **"Agregar Producto"**

### 📊 Ver Detalles del Producto

**Desde Explorar:**
1. Toca cualquier producto
2. Usa el **botón de corazón** en la barra superior para agregar/quitar de favoritos
3. Al agregarlo, aparece automáticamente la opción de **asignar a colección**

**Desde Favoritos:**
1. Toca cualquier producto
2. Visualiza el **historial de precios** en gráfico interactivo
3. Selecciona la **temporalidad**: 3 días, 7 días, 20 días o Todo
4. Toca cualquier punto del gráfico para ver precio y fecha exactos
5. Visualiza estadísticas: Precio Actual, Mínimo, Máximo y Promedio
6. Establece o edita el **precio objetivo**
7. Asigna el producto a una **colección**
8. Abre el producto directamente en **Amazon**
9. Elimina el producto de tus favoritos

### 🏷️ Ofertas y Alertas

- **Ofertas**: Filtra productos con descuentos activos (usa la búsqueda para encontrar ofertas específicas)
- **Alertas**: Muestra productos que alcanzaron su precio objetivo

### 🔄 Actualizar Precios

- **Automático**: Los precios se actualizan cada 30 minutos mediante cron jobs
- **Manual**: Desliza hacia abajo en cualquier lista para refrescar
- **Realtime**: Los cambios se sincronizan automáticamente entre dispositivos

## 🏗️ Arquitectura

```
lib/
├── config/                    # Configuración de la app
│   └── app_colors.dart       # Paleta de colores y temas
├── models/                    # Modelos de datos
│   ├── product.dart          # Modelo de producto
│   ├── price_history.dart    # Historial de precios
│   └── favorite_collection.dart # Colecciones de favoritos
├── providers/                 # Gestión de estado (Provider)
│   └── product_provider.dart # Estado global de productos
├── screens/                   # Pantallas principales
│   ├── home_screen.dart      # Navegación con tabs
│   ├── add_product_screen.dart # Agregar productos
│   ├── product_detail_screen.dart # Detalles del producto
│   ├── settings_screen.dart  # Configuración
│   └── tabs/                 # Pestañas
│       ├── explore_screen.dart    # Explorar productos
│       ├── favorites_screen.dart  # Favoritos y colecciones
│       ├── discounts_screen.dart  # Ofertas
│       └── alerts_screen.dart     # Alertas de precio
├── services/                  # Servicios externos
│   ├── amazon_service.dart   # Scraping de Amazon
│   ├── database_service.dart # SQLite local
│   ├── supabase_database_service.dart # Supabase cloud
│   └── notification_service.dart # Push notifications
├── utils/                     # Utilidades
│   └── format_utils.dart     # Formateo de precios y fechas
├── widgets/                   # Componentes reutilizables
│   ├── common/               # Widgets comunes
│   │   ├── search_bar_widget.dart
│   │   ├── gradient_button.dart
│   │   └── empty_state_widget.dart
│   ├── home/                 # Widgets del home
│   │   └── tab_content_widget.dart
│   ├── product_card.dart     # Tarjeta de producto
│   ├── product_card_compact.dart
│   └── interactive_price_chart.dart # Gráfico de precios
└── main.dart                  # Punto de entrada

supabase/
├── functions/                 # Edge Functions
│   ├── add-product/          # Agregar producto vía scraping
│   ├── refresh-prices/       # Actualizar precios
│   ├── refresh-all-prices/   # Actualizar todos los precios
│   └── send-price-alert/     # Enviar notificaciones
└── migrations/               # Migraciones de BD
    ├── price_alerts.sql
    └── fcm_tokens.sql
```

## 📦 Dependencias Principales

### Core
- **flutter**: SDK de Flutter (3.9.2+)
- **cupertino_icons**: Iconos nativos de iOS

### Estado y Datos
- **provider** (^6.1.1): Gestión de estado reactivo
- **sqflite** (^2.3.0): Base de datos local SQLite
- **supabase_flutter** (^2.5.0): Backend en la nube con realtime
- **shared_preferences** (^2.2.2): Almacenamiento de preferencias

### UI y Visualización
- **fl_chart** (^0.66.0): Gráficos interactivos de precios
- **html** (^0.15.4): Parsing de HTML para scraping

### Networking
- **http** (^1.1.0): Peticiones HTTP
- **url_launcher** (^6.2.2): Abrir URLs externas

### Notificaciones
- **firebase_core** (^3.6.0): Core de Firebase
- **firebase_messaging** (^15.1.3): Push notifications
- **flutter_local_notifications** (^16.3.0): Notificaciones locales

### Utilidades
- **intl** (^0.19.0): Formateo de moneda y fechas
- **path_provider** (^2.1.1): Rutas del sistema de archivos

## 🔧 Sistema de Scraping y Actualización

### Scraping de Amazon

La aplicación utiliza **scraping directo** de Amazon US para obtener datos de productos:

**Características:**
- ✅ **100% Gratuito** - Sin APIs de pago
- ✅ **Datos en tiempo real** - Precios actuales de Amazon
- ✅ **Extracción inteligente** - Múltiples métodos de parsing
- ✅ **Soporte URLs cortas** - Compatible con `a.co` y `amzn.to`
- ✅ **Historial automático** - Detecta precios min/max históricos

**Datos Extraídos:**
- Título del producto
- Precio actual y original (si hay descuento)
- Imágenes de alta calidad
- ASIN (identificador único de Amazon)
- Historial de precios (min/max)

### Edge Functions (Supabase)

**1. add-product** - Agregar productos vía scraping
- Scraping desde el servidor (evita bloqueos)
- Fallback cuando el scraping local falla
- Agrega automáticamente al historial

**2. refresh-prices** - Actualizar precio de un producto
- Actualiza precio actual
- Agrega punto al historial
- Verifica precio objetivo

**3. refresh-all-prices** - Cron job (cada 30 min)
- Actualiza todos los productos automáticamente
- Detecta cambios de precio
- Genera alertas cuando se alcanza precio objetivo

**4. send-price-alert** - Enviar notificaciones
- Push notifications vía Firebase
- Notificaciones in-app
- Historial de alertas enviadas

### ⚠️ Limitaciones del Scraping

- Amazon puede bloquear solicitudes excesivas
- Algunos productos pueden no tener todos los datos
- Recomendado: Usar Edge Functions para evitar bloqueos
- Los cron jobs manejan actualizaciones masivas de forma segura

## �️ Base de Datos (Supabase)

### Tablas Principales

**products** - Productos compartidos
- `id`, `asin`, `title`, `image_url`
- `current_price`, `original_price`, `currency`
- `url`, `created_by`, `last_updated`

**user_favorites** - Favoritos de usuarios
- `user_id`, `product_id`
- `target_price`, `is_tracking`
- `collection_id`, `added_at`

**favorite_collections** - Colecciones personalizadas
- `id`, `user_id`, `name`, `description`
- `icon`, `color`, `created_at`

**price_history** - Historial de precios
- `id`, `product_id`, `price`, `timestamp`

**price_alerts** - Alertas generadas
- `user_id`, `product_id`
- `target_price`, `current_price`
- `notified`, `created_at`

**fcm_tokens** - Tokens para notificaciones
- `user_id`, `token`, `platform`

### Realtime Subscriptions

La app se suscribe automáticamente a cambios en:
- `products` - Nuevos productos o actualizaciones
- `user_favorites` - Cambios en favoritos del usuario
- `price_history` - Nuevos puntos de precio

## �📱 Compatibilidad

- ✅ **iOS 12.0+**
- ✅ **iPhone y iPad**
- ✅ **Modo claro y oscuro**
- ✅ **Orientación vertical**
- ✅ **Notificaciones push**

## � Características Implementadas

- ✅ Explorar productos de otros usuarios
- ✅ Sistema de favoritos con colecciones
- ✅ Búsqueda por nombre de producto
- ✅ Botón de favoritos en explorar y detalle
- ✅ Gráficos interactivos de precios
- ✅ Notificaciones push cuando baja el precio
- ✅ Sincronización en tiempo real (Supabase)
- ✅ Actualización automática de precios (cron jobs)
- ✅ Soporte para URLs cortas de Amazon
- ✅ Historial completo de precios

## 🔮 Próximas Características

- [ ] Compartir productos con amigos
- [ ] Exportar historial de precios a CSV
- [ ] Soporte para Amazon México, España, etc.
- [ ] Widget de iOS para precios rápidos
- [ ] Comparación de precios entre productos
- [ ] Estadísticas de ahorro mensual

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 👨‍💻 Autor

**Juan Garcia** - [GitHub](https://github.com/JuanGarcia162)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request para sugerencias y mejoras.

---

**⭐ Si te gusta este proyecto, dale una estrella en GitHub!**
