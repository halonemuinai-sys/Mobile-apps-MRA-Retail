-- Tabel terstruktur untuk barang yang diminati per kunjungan
CREATE TABLE IF NOT EXISTS traffic_items (
  id          bigserial PRIMARY KEY,
  traffic_id  bigint NOT NULL REFERENCES mirror_traffic(id) ON DELETE CASCADE,
  item_code   text    NOT NULL DEFAULT '',
  sap_code    text    NOT NULL DEFAULT '',
  deskripsi   text    NOT NULL DEFAULT '',
  harga       numeric NOT NULL DEFAULT 0,
  kategori    text    NOT NULL DEFAULT '',
  koleksi     text    NOT NULL DEFAULT '',
  created_at  timestamptz DEFAULT now()
);

-- Index untuk query cepat per traffic_id
CREATE INDEX IF NOT EXISTS idx_traffic_items_traffic_id ON traffic_items(traffic_id);

-- Tambah kolom diskon_pct ke mirror_traffic (jika belum ada)
ALTER TABLE mirror_traffic ADD COLUMN IF NOT EXISTS diskon_pct numeric DEFAULT 0;

-- Enable RLS (opsional, sesuaikan policy dengan kebutuhan)
ALTER TABLE traffic_items ENABLE ROW LEVEL SECURITY;

-- Policy: semua authenticated user bisa baca & tulis
CREATE POLICY "allow_all_authenticated" ON traffic_items
  FOR ALL USING (auth.role() = 'authenticated');
