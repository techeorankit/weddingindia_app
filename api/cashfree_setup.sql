-- ============================================================
--  Cashfree Payment Gateway Setup
--  Run this SQL once on your server DB
-- ============================================================

-- 1. App settings table — admin panel se keys store hongi
CREATE TABLE IF NOT EXISTS `app_settings` (
  `id`         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `key`        VARCHAR(100) NOT NULL UNIQUE,
  `value`      TEXT,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Default Cashfree keys (empty — admin se fill karein)
INSERT IGNORE INTO `app_settings` (`key`, `value`) VALUES
  ('cashfree_app_id',       ''),
  ('cashfree_secret_key',   ''),
  ('cashfree_environment',  'sandbox'),   -- 'sandbox' ya 'production'
  ('cashfree_enabled',      '0');

-- 2. Payments table — har transaction track hogi
CREATE TABLE IF NOT EXISTS `payments` (
  `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`         INT UNSIGNED NOT NULL,
  `plan_id`         INT UNSIGNED NOT NULL,
  `cf_order_id`     VARCHAR(100) NOT NULL UNIQUE COMMENT 'Cashfree order id',
  `cf_payment_id`   VARCHAR(100) DEFAULT NULL COMMENT 'Cashfree payment id after success',
  `amount`          DECIMAL(10,2) NOT NULL,
  `currency`        VARCHAR(10) NOT NULL DEFAULT 'INR',
  `status`          ENUM('PENDING','SUCCESS','FAILED','CANCELLED') DEFAULT 'PENDING',
  `payment_session_id` VARCHAR(255) DEFAULT NULL COMMENT 'Used for SDK / web checkout',
  `webhook_data`    JSON DEFAULT NULL,
  `created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user    (`user_id`),
  INDEX idx_status  (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
