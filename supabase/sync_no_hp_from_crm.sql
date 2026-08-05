-- ============================================================
-- 1. BACKFILL: Isi no_hp + nama_panggilan dari crm_profiling
--    untuk semua record mirror_traffic yang masih kosong
-- ============================================================
UPDATE mirror_traffic mt
SET
  no_hp          = cp.no_hp,
  email          = CASE WHEN (mt.email IS NULL OR mt.email = '')
                        THEN cp.email
                        ELSE mt.email END,
  nama_panggilan = CASE WHEN (mt.nama_panggilan IS NULL OR mt.nama_panggilan = '')
                        THEN cp.nama_panggilan
                        ELSE mt.nama_panggilan END
FROM crm_profiling cp
WHERE LOWER(TRIM(mt.customer_name)) = LOWER(TRIM(cp.nama_lengkap))
  AND (mt.no_hp IS NULL OR mt.no_hp = '');


-- ============================================================
-- 2. TRIGGER: Auto-isi no_hp saat row baru masuk mirror_traffic
-- ============================================================

-- Function yang dicari ke crm_profiling berdasarkan customer_name
CREATE OR REPLACE FUNCTION fn_fill_no_hp_from_crm()
RETURNS TRIGGER AS $$
DECLARE
  v_no_hp          text;
  v_email          text;
  v_nama_panggilan text;
BEGIN
  -- Hanya isi jika no_hp masih kosong
  IF NEW.no_hp IS NULL OR NEW.no_hp = '' THEN
    SELECT no_hp, email, nama_panggilan
    INTO v_no_hp, v_email, v_nama_panggilan
    FROM crm_profiling
    WHERE LOWER(TRIM(nama_lengkap)) = LOWER(TRIM(NEW.customer_name))
    LIMIT 1;

    IF v_no_hp IS NOT NULL AND v_no_hp != '' THEN
      NEW.no_hp := v_no_hp;
    END IF;

    IF (NEW.email IS NULL OR NEW.email = '')
       AND v_email IS NOT NULL AND v_email != '' THEN
      NEW.email := v_email;
    END IF;

    IF (NEW.nama_panggilan IS NULL OR NEW.nama_panggilan = '')
       AND v_nama_panggilan IS NOT NULL THEN
      NEW.nama_panggilan := v_nama_panggilan;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Pasang trigger ke mirror_traffic
DROP TRIGGER IF EXISTS trg_fill_no_hp ON mirror_traffic;

CREATE TRIGGER trg_fill_no_hp
  BEFORE INSERT OR UPDATE OF customer_name, no_hp
  ON mirror_traffic
  FOR EACH ROW
  EXECUTE FUNCTION fn_fill_no_hp_from_crm();
