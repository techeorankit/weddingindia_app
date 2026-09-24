-- ============================================================
--  Advertisements Setup SQL
--  Run once on server DB
-- ============================================================

-- Ads table
CREATE TABLE IF NOT EXISTS `advertisements` (
  `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title`        VARCHAR(200) NOT NULL,
  `description`  TEXT DEFAULT NULL,
  `media_type`   ENUM('image','video') NOT NULL DEFAULT 'image',
  `media_url`    VARCHAR(500) NOT NULL COMMENT 'Uploaded file URL',
  `click_url`    VARCHAR(500) DEFAULT NULL COMMENT 'URL to open on tap',
  `advertiser`   VARCHAR(200) DEFAULT NULL COMMENT 'Advertiser name / company',
  `phone`        VARCHAR(20)  DEFAULT NULL COMMENT 'Advertiser contact',
  `position`     INT NOT NULL DEFAULT 5 COMMENT 'Show after every N profiles',
  `is_active`    TINYINT(1) NOT NULL DEFAULT 1,
  `impressions`  INT UNSIGNED NOT NULL DEFAULT 0,
  `clicks`       INT UNSIGNED NOT NULL DEFAULT 0,
  `starts_at`    DATETIME DEFAULT NULL,
  `ends_at`      DATETIME DEFAULT NULL,
  `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_active (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- App general settings (contact, whatsapp, chatbot, etc.)
INSERT IGNORE INTO `app_settings` (`key`, `value`) VALUES
  ('contact_phone',     '+91 9999999999'),
  ('contact_whatsapp',  '919999999999'),
  ('contact_email',     'support@weddingindiamatrimony.com'),
  ('whatsapp_message',  'Hello, I need help with Wedding India Matrimony app.'),
  ('app_name',          'Wedding India Matrimony'),
  ('chatbot_enabled',   '1'),
  ('ads_enabled',       '1'),
  ('ads_interval',      '4');
