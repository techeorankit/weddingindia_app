USE wedding_india_db;

CREATE TABLE IF NOT EXISTS app_content (
    id INT AUTO_INCREMENT PRIMARY KEY,
    content_key VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    body TEXT NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO app_content (content_key, title, body, sort_order, is_active) VALUES
('privacy', 'Privacy Policy', 'Add your privacy policy here.', 0, 1),
('terms', 'Terms & Conditions', 'Add your terms and conditions here.', 1, 1),
('about', 'About Us', 'Add your about us content here.', 2, 1),
('help', 'Help Line', 'Add your help line details here.', 3, 1)
ON DUPLICATE KEY UPDATE
    title = VALUES(title),
    body = VALUES(body),
    sort_order = VALUES(sort_order),
    is_active = VALUES(is_active);

-- Run these statements once to enable profile-view packages.
ALTER TABLE upgrade_plans
    ADD COLUMN profile_limit INT NOT NULL DEFAULT 2,
    ADD COLUMN duration_months INT NOT NULL DEFAULT 1;

CREATE TABLE IF NOT EXISTS user_subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    plan_id INT NOT NULL,
    profile_limit INT NOT NULL,
    profiles_viewed INT NOT NULL DEFAULT 0,
    starts_at DATETIME NOT NULL,
    expires_at DATETIME NOT NULL,
    payment_reference VARCHAR(150) DEFAULT NULL,
    status ENUM('active', 'expired', 'cancelled') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_subscription_user (user_id, status, expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS profile_views (
    id INT AUTO_INCREMENT PRIMARY KEY,
    viewer_id INT NOT NULL,
    profile_id INT NOT NULL,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_profile_view (viewer_id, profile_id),
    INDEX idx_viewer (viewer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS user_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    document_path VARCHAR(255) NOT NULL,
    document_type ENUM('Aadhaar Card', 'PAN Card', 'Voter ID', 'Passport') NOT NULL,
    original_name VARCHAR(255) DEFAULT NULL,
    selfie_path VARCHAR(255) DEFAULT NULL,
    selfie_name VARCHAR(255) DEFAULT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_document_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE user_documents
    ADD COLUMN IF NOT EXISTS document_type ENUM('Aadhaar Card', 'PAN Card', 'Voter ID', 'Passport') NOT NULL DEFAULT 'Aadhaar Card',
    ADD COLUMN IF NOT EXISTS selfie_path VARCHAR(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS selfie_name VARCHAR(255) DEFAULT NULL;
