import { setGlobalThemeSchema } from './theme.validation.js';
import { getGlobalThemeSetting, setGlobalThemeSetting } from './theme.service.js';

export async function getTheme(req, res, next) {
  try {
    const setting = await getGlobalThemeSetting();
    res.status(200).json(setting);
  } catch (err) {
    next(err);
  }
}

export async function updateTheme(req, res, next) {
  try {
    const payload = setGlobalThemeSchema.parse(req.body);
    const setting = await setGlobalThemeSetting(payload.theme, req.user?.userId ?? null);

    res.status(200).json({
      message: 'Global theme updated successfully',
      ...setting
    });
  } catch (err) {
    next(err);
  }
}