BEGIN;

-- =========================================================
-- 1) USER_ACCOUNT (10)
-- =========================================================
INSERT INTO user_account (full_name, email, phone, password_hash, user_type)
SELECT
  'User ' || i,
  'user' || i || '@mail.com',
  '55500000' || i,
  'hash' || i,
  CASE
    WHEN i <= 5 THEN 'RENTER'
    WHEN i <= 8 THEN 'SELLER_ADMIN'
    ELSE 'SELLER_STAFF'
  END
FROM generate_series(1,10) i;

-- =========================================================
-- 2) RENTER_PROFILE (10)
-- =========================================================
INSERT INTO renter_profile (user_id, driver_license_no, license_expiry_date, address)
SELECT
  user_id,
  'DL-' || user_id,
  CURRENT_DATE + INTERVAL '5 years',
  'Ankara Address ' || user_id
FROM user_account
ORDER BY user_id
LIMIT 10;

-- =========================================================
-- 3) SELLER_COMPANY (10)
-- =========================================================
INSERT INTO seller_company (company_name, tax_no, company_email, company_phone, address)
SELECT
  'Company ' || i,
  'TAX' || i,
  'company' || i || '@mail.com',
  '31200000' || i,
  'Company Address ' || i
FROM generate_series(1,10) i;

-- =========================================================
-- 4) COMPANY_USER (10)
-- =========================================================
INSERT INTO company_user (company_id, user_id, role_in_company)
SELECT
  i,
  i,
  'OWNER'
FROM generate_series(1,10) i;

-- =========================================================
-- 5) BRANCH (10)
-- =========================================================
INSERT INTO branch (company_id, name, city, address, phone)
SELECT
  i,
  'Branch ' || i,
  'Ankara',
  'Branch Address ' || i,
  '31211111' || i
FROM generate_series(1,10) i;

-- =========================================================
-- 6) VEHICLE_CLASS (10)
-- =========================================================
INSERT INTO vehicle_class (class_name, daily_price, deposit_amount, late_fee_per_hour)
SELECT
  'Class ' || i,
  500 + (i * 50),
  2000,
  50
FROM generate_series(1,10) i;

-- =========================================================
-- 7) VEHICLE (10)
-- =========================================================
INSERT INTO vehicle (
  plate_no, vin, brand, model, model_year,
  color, mileage, status, company_id, branch_id, class_id
)
SELECT
  '06ABC' || i,
  'VIN' || i,
  'Toyota',
  'Corolla',
  2020,
  'White',
  10000 * i,
  'AVAILABLE',
  i,
  i,
  i
FROM generate_series(1,10) i;

-- =========================================================
-- 8) LISTING (10)
-- =========================================================
INSERT INTO listing (
  company_id, vehicle_id, title, description,
  daily_price_override, min_rental_days, deposit_amount
)
SELECT
  v.company_id,
  v.vehicle_id,
  'Listing ' || v.vehicle_id,
  'Vehicle based listing',
  700,
  1,
  2000
FROM vehicle v
LIMIT 10;

-- =========================================================
-- 9) RESERVATION (10)
-- =========================================================
INSERT INTO reservation (
  listing_id, renter_user_id,
  start_datetime, end_datetime,
  pickup_branch_id, dropoff_branch_id,
  status, assigned_vehicle_id
)
SELECT
  l.listing_id,
  u.user_id,
  CURRENT_TIMESTAMP + (i || ' days')::INTERVAL,
  CURRENT_TIMESTAMP + ((i+1) || ' days')::INTERVAL,
  i,
  i,
  'CONFIRMED',
  i
FROM generate_series(1,10) i
JOIN listing l ON l.listing_id = i
JOIN user_account u ON u.user_id = i;

-- =========================================================
-- 10) RENTAL (10)  (overlap yok)
-- =========================================================
INSERT INTO rental (
  reservation_id, company_id, renter_user_id, vehicle_id,
  rental_start_datetime, rental_end_planned,
  status, start_mileage, total_amount
)
SELECT
  r.reservation_id,
  v.company_id,
  r.renter_user_id,
  v.vehicle_id,
  r.start_datetime,
  r.end_datetime,
  'OPEN',
  v.mileage,
  3000
FROM reservation r
JOIN vehicle v ON v.vehicle_id = r.assigned_vehicle_id;

-- =========================================================
-- 11) PAYMENT (10)
-- =========================================================
INSERT INTO payment (
  rental_id, amount, method, payment_type, status, reference_no
)
SELECT
  rental_id,
  3000,
  'CARD',
  'RENTAL_FEE',
  'PAID',
  'REF' || rental_id
FROM rental;

-- =========================================================
-- 12) COMMISSION (10)
-- =========================================================
INSERT INTO commission (
  rental_id, commission_rate, commission_amount, seller_payout_amount, payout_status
)
SELECT
  rental_id,
  0.10,
  300,
  2700,
  'PENDING'
FROM rental;

-- =========================================================
-- 13) MAINTENANCE (10)
-- =========================================================
INSERT INTO maintenance (
  vehicle_id, start_date, end_date,
  maintenance_type, cost, note
)
SELECT
  vehicle_id,
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE - INTERVAL '25 days',
  'GENERAL',
  1500,
  'Routine maintenance'
FROM vehicle;

COMMIT;
