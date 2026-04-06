import * as storeService from './store.service.js';
import { pool } from '../../db/pool.js';
export async function getInventoryHandler(req, res, next) {
  try {
    const items = await storeService.getInventory({
      userId: req.user.userId,
      category: req.query.category,
      search: req.query.search
    });
    res.json({ items });
  } catch (err) { next(err); }
}

export async function getItemHandler(req, res, next) {
  try {
    const item = await storeService.getItemById(req.params.id);
    if (!item) return res.status(404).json({ message: 'Item not found' });
    res.json({ item });
  } catch (err) { next(err); }
}

export async function createItemHandler(req, res, next) {
  try {
    const item = await storeService.createItem({
      ...req.body,
      userId: req.user.userId // req.user.sub is from older version, using userId from current authMiddleware
    }, req.file);
    res.status(201).json({ item });
  } catch (err) { next(err); }
}

export async function updateItemHandler(req, res, next) {
  try {
    const item = await storeService.updateItem(req.params.id, req.body);
    if (!item) return res.status(404).json({ message: 'Item not found' });
    res.json({ item });
  } catch (err) { next(err); }
}

export async function deleteItemHandler(req, res, next) {
  try {
    const deleted = await storeService.deleteItem(req.params.id);
    if (!deleted) return res.status(404).json({ message: 'Item not found' });
    res.json({ message: 'Item deleted' });
  } catch (err) { next(err); }
}

export async function getRevenueHandler(req, res, next) {
  try {
    const stats = await storeService.getRevenueStats(req.user.userId);
    res.json(stats);
  } catch (err) { next(err); }
}

export async function getOverviewHandler(req, res, next) {
  try {
    const overview = await storeService.getOverviewStats(req.user.userId);
    res.json(overview);
  } catch (err) { next(err); }
}

export async function runAprioriHandler(req, res, next) {
  try {
    const minSupport = parseFloat(req.query.minSupport) || 0.1;
    const minConfidence = parseFloat(req.query.minConfidence) || 0.5;
    const result = await storeService.runApriori(minSupport, minConfidence);
    
    // Auto save generated combos
    if (result.combos && result.combos.length > 0) {
      await pool.query('DELETE FROM store_combos');
      for (const combo of result.combos) {
        await storeService.saveCombo(combo);
      }
    }
    
    res.json(result);
  } catch (err) { next(err); }
}

export async function getCombosHandler(req, res, next) {
  try {
    const combos = await storeService.getSavedCombos();
    res.json({ combos });
  } catch (err) { next(err); }
}

export async function saveComboHandler(req, res, next) {
  try {
    const combo = await storeService.saveCombo(req.body);
    res.status(201).json({ combo });
  } catch (err) { next(err); }
}

export async function loadDatasetHandler(req, res, next) {
  try {
    const result = await storeService.loadDatasetToInventory(req.user.userId);
    res.json({ message: 'Dataset loaded', ...result });
  } catch (err) { next(err); }
}

export async function importExcelHandler(req, res, next) {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded' });
    
    const result = await storeService.importFromExcel(req.user.userId, req.file.path);
    res.json({ 
      message: 'Excel import completed', 
      count: result.count,
      errors: result.errors 
    });
  } catch (err) { next(err); }
}

export async function getMarketHandler(req, res, next) {
  try {
    const items = await storeService.getMarketItems({
      category: req.query.category,
      search: req.query.search
    });
    res.json({ items });
  } catch (err) { next(err); }
}

export async function buyItemHandler(req, res, next) {
  try {
    const result = await storeService.buyItem(req.user.userId, req.params.id);
    if (!result.success) {
      return res.status(400).json({ message: result.message });
    }
    res.json({ message: 'Mua thành công', ...result });
  } catch (err) { next(err); }
}

export async function getCartHandler(req, res, next) {
  try {
    const rows = await storeService.getCart(req.user.userId);
    res.json(rows);
  } catch (err) { next(err); }
}

export async function addToCartHandler(req, res, next) {
  try {
    const result = await storeService.addToCart(req.user.userId, req.body.itemId);
    res.json(result);
  } catch (err) { next(err); }
}

export async function removeFromCartHandler(req, res, next) {
  try {
    const success = await storeService.removeFromCart(req.user.userId, req.params.itemId);
    res.json({ success });
  } catch (err) { next(err); }
}

export async function checkoutCartHandler(req, res, next) {
  try {
    const result = await storeService.checkoutCart(
      req.user.userId,
      req.body.itemIds,
      req.body.voucherCode,
    );
    if (!result.success) {
      return res.status(400).json({ message: result.message });
    }
    res.json(result);
  } catch (err) { next(err); }
}
