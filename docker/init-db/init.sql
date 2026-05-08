-- ── Private On-Premise PHI Database ──────────────────────────────────────
-- Simulates the private layer: all Tier 1 raw PHI lives here, never in AWS.

-- Tier 1: raw PHI — names, diagnoses, SSNs, medications with patient identifiers
CREATE TABLE patients (
  id             SERIAL PRIMARY KEY,
  patient_id     VARCHAR(50)  UNIQUE NOT NULL,
  full_name      VARCHAR(200) NOT NULL,        -- PHI
  date_of_birth  DATE         NOT NULL,        -- PHI
  ssn_hash       VARCHAR(64),                  -- SHA-256 hash, never stored plaintext
  diagnosis      TEXT,                         -- PHI
  medications    TEXT,                         -- PHI
  data_tier      INTEGER      DEFAULT 1,       -- 1=PHI, 2=de-identified, 3=aggregate
  erased         BOOLEAN      DEFAULT FALSE,   -- GD-02 soft-flag (key destroyed in prod)
  created_at     TIMESTAMP    DEFAULT NOW()
);

-- Consent records — checked by HC-02 and GD-01 before every access
CREATE TABLE consent_records (
  id           SERIAL PRIMARY KEY,
  patient_id   VARCHAR(50)  NOT NULL,
  purpose      VARCHAR(100) NOT NULL,  -- treatment | research | billing
  granted      BOOLEAN      NOT NULL,
  granted_by   VARCHAR(100),
  granted_at   TIMESTAMP    DEFAULT NOW(),
  expires_at   TIMESTAMP,
  lawful_basis VARCHAR(50)             -- GDPR Art.6 basis
);

-- Immutable audit log — HC-03: every access event recorded, denials included
CREATE TABLE audit_log (
  id              SERIAL PRIMARY KEY,
  event_id        VARCHAR(50)  UNIQUE NOT NULL,
  actor_id        VARCHAR(100) NOT NULL,
  actor_role      VARCHAR(50)  NOT NULL,
  resource_id     VARCHAR(100) NOT NULL,
  action          VARCHAR(50)  NOT NULL,
  decision        VARCHAR(10)  NOT NULL,  -- ALLOW | DENY
  rule_triggered  VARCHAR(20),
  reason          TEXT,
  ip_address      VARCHAR(45),
  timestamp       TIMESTAMP    DEFAULT NOW()
);

-- ── Seed data ─────────────────────────────────────────────────────────────

INSERT INTO patients (patient_id, full_name, date_of_birth, ssn_hash, diagnosis, medications)
VALUES
  ('P001', 'John Doe',     '1980-05-15', 'e3b0c44298fc1c149afbf4c8996fb924', 'Hypertension',      'Lisinopril 10mg'),
  ('P002', 'Jane Smith',   '1992-09-22', 'a665a45920422f9d417e489f408b0ce4', 'Type 2 Diabetes',   'Metformin 500mg'),
  ('P003', 'Bob Johnson',  '1975-03-10', 'b14a7b8059d9c055954c926acda7e700', 'Asthma',            'Albuterol inhaler');

INSERT INTO consent_records (patient_id, purpose, granted, granted_by, lawful_basis)
VALUES
  ('P001', 'treatment', TRUE,  'P001',   'consent'),
  ('P001', 'research',  FALSE,  NULL,    NULL),
  ('P001', 'billing',   TRUE,  'P001',   'contract'),
  ('P002', 'treatment', TRUE,  'P002',   'consent'),
  ('P002', 'billing',   TRUE,  'P002',   'contract'),
  ('P003', 'treatment', FALSE,  NULL,    NULL);   -- P003 has NOT consented — triggers HC-02 DENY
