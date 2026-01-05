-- =========================================================
-- SCARMS Marketplace Schema (PostgreSQL)
-- Entities: user_account, renter_profile, seller_company, company_user,
--           branch, vehicle_class, vehicle, listing, reservation, rental,
--           payment, commission, maintenance
-- =========================================================

-- (�stersen ba�tan temizlemek i�in)
-- DROP TABLE IF EXISTS maintenance, commission, payment, rental, reservation, listing,
--                    vehicle, branch, company_user, seller_company, renter_profile,
--                    vehicle_class, user_account CASCADE;



-- =========================================================
-- RESET (optional): clean start
-- =========================================================
DROP TABLE IF EXISTS
  maintenance, commission, payment, rental, reservation, listing,
  vehicle, branch, company_user, seller_company, renter_profile,
  vehicle_class, user_account
CASCADE;
-- ---------------------------------------------------------
-- 1) USER
-- ---------------------------------------------------------
CREATE TABLE user_account (
  user_id        BIGSERIAL PRIMARY KEY,
  full_name      VARCHAR(120) NOT NULL,
  email          VARCHAR(120) NOT NULL UNIQUE,
  phone          VARCHAR(30),
  password_hash  TEXT NOT NULL,
  user_type      VARCHAR(20) NOT NULL
                 CHECK (user_type IN ('RENTER','SELLER_ADMIN','SELLER_STAFF')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active      BOOLEAN NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------
-- 2) RENTER_PROFILE (optional but recommended)
-- ---------------------------------------------------------
CREATE TABLE renter_profile (
  renter_id           BIGSERIAL PRIMARY KEY,
  user_id             BIGINT NOT NULL UNIQUE REFERENCES user_account(user_id) ON DELETE CASCADE,
  driver_license_no   VARCHAR(40) NOT NULL UNIQUE,
  license_expiry_date DATE NOT NULL,
  address             TEXT
);

-- ---------------------------------------------------------
-- 3) SELLER_COMPANY
-- ---------------------------------------------------------
CREATE TABLE seller_company (
  company_id     BIGSERIAL PRIMARY KEY,
  company_name   VARCHAR(160) NOT NULL,
  tax_no         VARCHAR(40)  NOT NULL UNIQUE,
  company_email  VARCHAR(120),
  company_phone  VARCHAR(30),
  address        TEXT,
  status         VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
                CHECK (status IN ('ACTIVE','SUSPENDED')),
  rating_avg     NUMERIC(3,2) CHECK (rating_avg IS NULL OR (rating_avg >= 0 AND rating_avg <= 5))
);

-- ---------------------------------------------------------
-- 4) COMPANY_USER (company <-> user membership)
-- ---------------------------------------------------------
CREATE TABLE company_user (
  company_user_id  BIGSERIAL PRIMARY KEY,
  company_id       BIGINT NOT NULL REFERENCES seller_company(company_id) ON DELETE CASCADE,
  user_id          BIGINT NOT NULL REFERENCES user_account(user_id) ON DELETE CASCADE,
  role_in_company  VARCHAR(20) NOT NULL
                  CHECK (role_in_company IN ('OWNER','MANAGER','STAFF')),
  UNIQUE (company_id, user_id)
);

-- ---------------------------------------------------------
-- 5) BRANCH
-- ---------------------------------------------------------
CREATE TABLE branch (
  branch_id   BIGSERIAL PRIMARY KEY,
  company_id  BIGINT NOT NULL REFERENCES seller_company(company_id) ON DELETE CASCADE,
  name        VARCHAR(120) NOT NULL,
  city        VARCHAR(80) NOT NULL,
  address     TEXT,
  phone       VARCHAR(30)
);

-- ---------------------------------------------------------
-- 6) VEHICLE_CLASS
-- ---------------------------------------------------------
CREATE TABLE vehicle_class (
  class_id           BIGSERIAL PRIMARY KEY,
  class_name         VARCHAR(60) NOT NULL UNIQUE,
  daily_price        NUMERIC(12,2) NOT NULL CHECK (daily_price >= 0),
  deposit_amount     NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (deposit_amount >= 0),
  late_fee_per_hour  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (late_fee_per_hour >= 0)
);

-- ---------------------------------------------------------
-- 7) VEHICLE
-- ---------------------------------------------------------
CREATE TABLE vehicle (
  vehicle_id   BIGSERIAL PRIMARY KEY,
  plate_no     VARCHAR(20) NOT NULL UNIQUE,
  vin          VARCHAR(40) UNIQUE,
  brand        VARCHAR(60) NOT NULL,
  model        VARCHAR(60) NOT NULL,
  model_year   INT CHECK (model_year IS NULL OR (model_year >= 1950 AND model_year <= 2100)),
  color        VARCHAR(40),
  mileage      INT NOT NULL DEFAULT 0 CHECK (mileage >= 0),
  status       VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE'
              CHECK (status IN ('AVAILABLE','RESERVED','RENTED','MAINTENANCE')),
  company_id   BIGINT NOT NULL REFERENCES seller_company(company_id) ON DELETE CASCADE,
  branch_id    BIGINT REFERENCES branch(branch_id) ON DELETE SET NULL,
  class_id     BIGINT NOT NULL REFERENCES vehicle_class(class_id)
);

CREATE INDEX idx_vehicle_company ON vehicle(company_id);
CREATE INDEX idx_vehicle_branch  ON vehicle(branch_id);
CREATE INDEX idx_vehicle_class   ON vehicle(class_id);

-- ---------------------------------------------------------
-- 8) LISTING (either vehicle-based or class-based)
-- ---------------------------------------------------------
CREATE TABLE listing (
  listing_id          BIGSERIAL PRIMARY KEY,
  company_id          BIGINT NOT NULL REFERENCES seller_company(company_id) ON DELETE CASCADE,
  vehicle_id          BIGINT REFERENCES vehicle(vehicle_id) ON DELETE SET NULL,
  class_id            BIGINT REFERENCES vehicle_class(class_id) ON DELETE SET NULL,
  title               VARCHAR(160) NOT NULL,
  description         TEXT,
  daily_price_override NUMERIC(12,2) CHECK (daily_price_override IS NULL OR daily_price_override >= 0),
  min_rental_days     INT NOT NULL DEFAULT 1 CHECK (min_rental_days >= 1),
  deposit_amount      NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (deposit_amount >= 0),
  pickup_policy       VARCHAR(20) NOT NULL DEFAULT 'BRANCH_PICKUP'
                      CHECK (pickup_policy IN ('BRANCH_PICKUP','DELIVERY')),
  active              BOOLEAN NOT NULL DEFAULT TRUE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Exactly one of vehicle_id or class_id must be provided
  CHECK ( (vehicle_id IS NOT NULL AND class_id IS NULL)
       OR (vehicle_id IS NULL AND class_id IS NOT NULL) )
);

CREATE INDEX idx_listing_company ON listing(company_id);
CREATE INDEX idx_listing_vehicle ON listing(vehicle_id);
CREATE INDEX idx_listing_class   ON listing(class_id);

-- ---------------------------------------------------------
-- 9) RESERVATION
-- ---------------------------------------------------------
CREATE TABLE reservation (
  reservation_id     BIGSERIAL PRIMARY KEY,
  listing_id         BIGINT NOT NULL REFERENCES listing(listing_id) ON DELETE RESTRICT,
  renter_user_id     BIGINT NOT NULL REFERENCES user_account(user_id) ON DELETE RESTRICT,

  start_datetime     TIMESTAMPTZ NOT NULL,
  end_datetime       TIMESTAMPTZ NOT NULL,

  pickup_branch_id   BIGINT REFERENCES branch(branch_id) ON DELETE SET NULL,
  dropoff_branch_id  BIGINT REFERENCES branch(branch_id) ON DELETE SET NULL,

  status             VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING','CONFIRMED','CANCELLED','EXPIRED','CONVERTED')),

  assigned_vehicle_id BIGINT REFERENCES vehicle(vehicle_id) ON DELETE SET NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

  CHECK (end_datetime > start_datetime)
);

CREATE INDEX idx_reservation_renter   ON reservation(renter_user_id);
CREATE INDEX idx_reservation_listing  ON reservation(listing_id);
CREATE INDEX idx_reservation_vehicle  ON reservation(assigned_vehicle_id);

-- ---------------------------------------------------------
-- 10) RENTAL
-- ---------------------------------------------------------
CREATE TABLE rental (
  rental_id            BIGSERIAL PRIMARY KEY,
  reservation_id       BIGINT UNIQUE REFERENCES reservation(reservation_id) ON DELETE SET NULL,

  company_id           BIGINT NOT NULL REFERENCES seller_company(company_id) ON DELETE RESTRICT,
  renter_user_id       BIGINT NOT NULL REFERENCES user_account(user_id) ON DELETE RESTRICT,
  vehicle_id           BIGINT NOT NULL REFERENCES vehicle(vehicle_id) ON DELETE RESTRICT,

  rental_start_datetime TIMESTAMPTZ NOT NULL,
  rental_end_planned    TIMESTAMPTZ NOT NULL,
  rental_end_actual     TIMESTAMPTZ,

  status               VARCHAR(20) NOT NULL DEFAULT 'OPEN'
                      CHECK (status IN ('OPEN','CLOSED','CANCELLED')),

  start_mileage        INT NOT NULL DEFAULT 0 CHECK (start_mileage >= 0),
  end_mileage          INT CHECK (end_mileage IS NULL OR end_mileage >= 0),

  total_amount         NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),

  CHECK (rental_end_planned > rental_start_datetime),
  CHECK (rental_end_actual IS NULL OR rental_end_actual >= rental_start_datetime),
  CHECK (end_mileage IS NULL OR end_mileage >= start_mileage)
);

CREATE INDEX idx_rental_company ON rental(company_id);
CREATE INDEX idx_rental_renter  ON rental(renter_user_id);
CREATE INDEX idx_rental_vehicle ON rental(vehicle_id);

-- ---------------------------------------------------------
-- 11) PAYMENT
-- ---------------------------------------------------------
CREATE TABLE payment (
  payment_id       BIGSERIAL PRIMARY KEY,
  rental_id        BIGINT NOT NULL REFERENCES rental(rental_id) ON DELETE CASCADE,
  payment_datetime TIMESTAMPTZ NOT NULL DEFAULT now(),
  amount           NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  method           VARCHAR(20) NOT NULL CHECK (method IN ('CASH','CARD','TRANSFER')),
  payment_type     VARCHAR(20) NOT NULL
                  CHECK (payment_type IN ('DEPOSIT','RENTAL_FEE','EXTRA','REFUND')),
  status           VARCHAR(20) NOT NULL DEFAULT 'PAID'
                  CHECK (status IN ('PAID','FAILED','REFUNDED')),
  reference_no     VARCHAR(80)
);

CREATE INDEX idx_payment_rental ON payment(rental_id);

-- ---------------------------------------------------------
-- 12) COMMISSION / PLATFORM_FEE
-- ---------------------------------------------------------
CREATE TABLE commission (
  fee_id              BIGSERIAL PRIMARY KEY,
  rental_id           BIGINT NOT NULL UNIQUE REFERENCES rental(rental_id) ON DELETE CASCADE,
  commission_rate     NUMERIC(6,4) NOT NULL CHECK (commission_rate >= 0),
  commission_amount   NUMERIC(12,2) NOT NULL CHECK (commission_amount >= 0),
  seller_payout_amount NUMERIC(12,2) NOT NULL CHECK (seller_payout_amount >= 0),
  payout_status       VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                     CHECK (payout_status IN ('PENDING','PAID')),
  payout_date         TIMESTAMPTZ
);

-- ---------------------------------------------------------
-- 13) MAINTENANCE (optional)
-- ---------------------------------------------------------
CREATE TABLE maintenance (
  maintenance_id   BIGSERIAL PRIMARY KEY,
  vehicle_id       BIGINT NOT NULL REFERENCES vehicle(vehicle_id) ON DELETE CASCADE,
  start_date       DATE NOT NULL,
  end_date         DATE,
  maintenance_type VARCHAR(20) NOT NULL
                  CHECK (maintenance_type IN ('OIL_CHANGE','REPAIR','TIRE','GENERAL')),
  cost             NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (cost >= 0),
  note             TEXT,
  CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_maint_vehicle ON maintenance(vehicle_id);

-- =========================================================
-- OPTIONAL (Recommended): Prevent overlapping rentals per vehicle
-- Uses range types + exclusion constraints (PostgreSQL feature)
-- =========================================================

-- Required extension for GiST indexes on scalar types
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Add generated rental period range (stored) for exclusion constraint
ALTER TABLE rental
  ADD COLUMN rental_period tstzrange
  GENERATED ALWAYS AS (tstzrange(rental_start_datetime, rental_end_planned, '[)')) STORED;

-- Prevent overlaps for OPEN rentals on same vehicle (basic protection)
-- Note: You can refine WHERE clause / statuses as needed.
ALTER TABLE rental
  ADD CONSTRAINT no_overlapping_rentals_per_vehicle
  EXCLUDE USING gist (
    vehicle_id WITH =,
    rental_period WITH &&
  )
  WHERE (status IN ('OPEN','CLOSED'));  -- istersen sadece OPEN yapars�n

-- =========================================================
-- OPTIONAL: Prevent overlaps for assigned-vehicle reservations too
-- (only for CONFIRMED reservations with assigned_vehicle_id)
-- =========================================================
ALTER TABLE reservation
  ADD COLUMN reservation_period tstzrange
  GENERATED ALWAYS AS (tstzrange(start_datetime, end_datetime, '[)')) STORED;

ALTER TABLE reservation
  ADD CONSTRAINT no_overlapping_confirmed_reservations_assigned_vehicle
  EXCLUDE USING gist (
    assigned_vehicle_id WITH =,
    reservation_period WITH &&
  )
  WHERE (status = 'CONFIRMED' AND assigned_vehicle_id IS NOT NULL);