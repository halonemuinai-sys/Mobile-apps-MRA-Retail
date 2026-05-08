-- Advisor PIN authentication table
-- PIN stored as SHA-256 hash (handled in Dart via crypto package)
CREATE TABLE IF NOT EXISTS advisor_pins (
  advisor_name TEXT PRIMARY KEY,
  pin_hash     TEXT NOT NULL,         -- SHA-256 of raw PIN
  role         TEXT DEFAULT 'advisor', -- advisor | senior_advisor | store_manager | asm | spv
  store        TEXT DEFAULT '',
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Seed default PIN '1234' for all existing advisors
-- SHA-256 of '1234' = 03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4
INSERT INTO advisor_pins (advisor_name, pin_hash, role, store)
SELECT
  name,
  '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4',
  'advisor',
  home_location
FROM advisors
ON CONFLICT (advisor_name) DO NOTHING;
