-- Migration: Add global app theme setting for system-wide theming

CREATE TABLE IF NOT EXISTS app_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_value VARCHAR(255) NOT NULL,
    updated_by UUID,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_app_settings_updated_by
        FOREIGN KEY (updated_by) REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

INSERT INTO app_settings (setting_key, setting_value)
VALUES ('global_theme', 'default')
ON CONFLICT (setting_key) DO NOTHING;
