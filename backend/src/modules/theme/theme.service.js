import { pool } from '../../db/pool.js';

const THEME_SETTING_KEY = 'global_theme';
const FALLBACK_THEME = 'default';
const ALLOWED_THEMES = new Set(['default', 'tet', 'valentine']);

let didInitThemeSettings = false;

function normalizeTheme(rawTheme) {
  const value = String(rawTheme ?? '').trim().toLowerCase();
  return ALLOWED_THEMES.has(value) ? value : FALLBACK_THEME;
}

async function ensureThemeSettingsStorage() {
  if (didInitThemeSettings) {
    return;
  }

  await pool.query(`
    CREATE TABLE IF NOT EXISTS app_settings (
      setting_key VARCHAR(100) PRIMARY KEY,
      setting_value VARCHAR(255) NOT NULL,
      updated_by UUID REFERENCES users(user_id) ON DELETE SET NULL,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await pool.query(
    `
      INSERT INTO app_settings (setting_key, setting_value)
      VALUES ($1, $2)
      ON CONFLICT (setting_key) DO NOTHING
    `,
    [THEME_SETTING_KEY, FALLBACK_THEME]
  );

  didInitThemeSettings = true;
}

export async function getGlobalThemeSetting() {
  await ensureThemeSettingsStorage();

  const result = await pool.query(
    `
      SELECT setting_value, updated_by, updated_at
      FROM app_settings
      WHERE setting_key = $1
      LIMIT 1
    `,
    [THEME_SETTING_KEY]
  );

  const row = result.rows[0] ?? {
    setting_value: FALLBACK_THEME,
    updated_by: null,
    updated_at: null
  };

  return {
    theme: normalizeTheme(row.setting_value),
    updatedBy: row.updated_by,
    updatedAt: row.updated_at
  };
}

export async function setGlobalThemeSetting(theme, updatedByUserId) {
  await ensureThemeSettingsStorage();
  const nextTheme = normalizeTheme(theme);

  const result = await pool.query(
    `
      INSERT INTO app_settings (setting_key, setting_value, updated_by, updated_at)
      VALUES ($1, $2, $3, NOW())
      ON CONFLICT (setting_key)
      DO UPDATE SET
        setting_value = EXCLUDED.setting_value,
        updated_by = EXCLUDED.updated_by,
        updated_at = NOW()
      RETURNING setting_value, updated_by, updated_at
    `,
    [THEME_SETTING_KEY, nextTheme, updatedByUserId ?? null]
  );

  const row = result.rows[0];
  return {
    theme: normalizeTheme(row.setting_value),
    updatedBy: row.updated_by,
    updatedAt: row.updated_at
  };
}