-- Tabla de productos (compartida entre todos los usuarios)
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  asin TEXT NOT NULL UNIQUE, -- ASIN único para evitar duplicados
  title TEXT NOT NULL,
  image_url TEXT NOT NULL,
  current_price REAL NOT NULL,
  original_price REAL,
  currency TEXT NOT NULL DEFAULT 'USD',
  url TEXT NOT NULL,
  last_updated TIMESTAMP WITH TIME ZONE NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Usuario que lo creó primero
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de historial de precios (compartida)
CREATE TABLE price_history (
  id TEXT PRIMARY KEY,
  product_id TEXT REFERENCES products(id) ON DELETE CASCADE,
  price REAL NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de colecciones de favoritos por usuario
CREATE TABLE favorite_collections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT, -- Nombre del icono (ej: 'heart', 'star', 'tag')
  color TEXT, -- Color en formato hex (ej: '#FF5733')
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de favoritos/seguimientos por usuario
CREATE TABLE user_favorites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id TEXT REFERENCES products(id) ON DELETE CASCADE,
  collection_id UUID REFERENCES favorite_collections(id) ON DELETE SET NULL, -- Colección a la que pertenece
  target_price REAL, -- Precio objetivo personalizado por usuario
  is_tracking BOOLEAN NOT NULL DEFAULT true,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, product_id) -- Un usuario no puede agregar el mismo producto dos veces
);

-- Índices para mejorar el rendimiento
CREATE INDEX idx_products_asin ON products(asin);
CREATE INDEX idx_products_created_by ON products(created_by);
CREATE INDEX idx_price_history_product_id ON price_history(product_id);
CREATE INDEX idx_price_history_timestamp ON price_history(timestamp);
CREATE INDEX idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_product_id ON user_favorites(product_id);
CREATE INDEX idx_user_favorites_collection_id ON user_favorites(collection_id);
CREATE INDEX idx_favorite_collections_user_id ON favorite_collections(user_id);

-- Habilitar Row Level Security (RLS)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_collections ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para products
-- Todos los usuarios autenticados pueden ver todos los productos
CREATE POLICY "Anyone can view products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

-- Todos los usuarios autenticados pueden insertar productos
CREATE POLICY "Anyone can insert products"
  ON products FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Todos los usuarios autenticados pueden actualizar productos (para actualizar precios)
CREATE POLICY "Anyone can update products"
  ON products FOR UPDATE
  TO authenticated
  USING (true);

-- Solo se puede eliminar un producto si no tiene favoritos de ningún usuario
-- (En la práctica, no deberíamos eliminar productos, solo remover de favoritos)
CREATE POLICY "Products cannot be deleted if they have favorites"
  ON products FOR DELETE
  TO authenticated
  USING (
    NOT EXISTS (
      SELECT 1 FROM user_favorites
      WHERE user_favorites.product_id = products.id
    )
  );

-- Políticas de seguridad para price_history
-- Todos los usuarios autenticados pueden ver el historial de precios
CREATE POLICY "Anyone can view price history"
  ON price_history FOR SELECT
  TO authenticated
  USING (true);

-- Solo se puede insertar historial de precios para productos que existen
-- La app se encargará de insertar automáticamente cuando detecte cambios de precio
CREATE POLICY "Can insert price history for existing products"
  ON price_history FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = price_history.product_id
    )
  );

-- Políticas de seguridad para user_favorites
-- Los usuarios solo pueden ver sus propios favoritos
CREATE POLICY "Users can view their own favorites"
  ON user_favorites FOR SELECT
  USING (auth.uid() = user_id);

-- Los usuarios solo pueden insertar sus propios favoritos
CREATE POLICY "Users can insert their own favorites"
  ON user_favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Los usuarios solo pueden actualizar sus propios favoritos
CREATE POLICY "Users can update their own favorites"
  ON user_favorites FOR UPDATE
  USING (auth.uid() = user_id);

-- Los usuarios solo pueden eliminar sus propios favoritos
CREATE POLICY "Users can delete their own favorites"
  ON user_favorites FOR DELETE
  USING (auth.uid() = user_id);

-- Políticas de seguridad para favorite_collections
-- Los usuarios solo pueden ver sus propias colecciones
CREATE POLICY "Users can view their own collections"
  ON favorite_collections FOR SELECT
  USING (auth.uid() = user_id);

-- Los usuarios solo pueden insertar sus propias colecciones
CREATE POLICY "Users can insert their own collections"
  ON favorite_collections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Los usuarios solo pueden actualizar sus propias colecciones
CREATE POLICY "Users can update their own collections"
  ON favorite_collections FOR UPDATE
  USING (auth.uid() = user_id);

-- Los usuarios solo pueden eliminar sus propias colecciones
CREATE POLICY "Users can delete their own collections"
  ON favorite_collections FOR DELETE
  USING (auth.uid() = user_id);
