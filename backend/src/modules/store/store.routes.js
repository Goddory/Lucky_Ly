import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import { authenticateToken } from '../../middleware/authMiddleware.js';
import {
  getInventoryHandler,
  getItemHandler,
  createItemHandler,
  updateItemHandler,
  deleteItemHandler,
  getRevenueHandler,
  runAprioriHandler,
  getCombosHandler,
  saveComboHandler,
  loadDatasetHandler,
  getOverviewHandler,
  importExcelHandler,
  getMarketHandler,
  buyItemHandler,
  getCartHandler,
  addToCartHandler,
  removeFromCartHandler,
  checkoutCartHandler
} from './store.controller.js';

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/store/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ storage: storage });

const router = Router();

// Middleware: phải đăng nhập + role = store_creator
function requireStoreCreator(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ message: 'Authentication required' });
  }
  if (req.user.role !== 'store_creator' && req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Store creator access required' });
  }
  next();
}

router.use(authenticateToken);

// Marketplace (Public for all auth users)
router.get('/market', getMarketHandler);
router.post('/market/buy/:id', buyItemHandler);

// Cart Endpoints
router.get('/market/cart', getCartHandler);
router.post('/market/cart', addToCartHandler);
router.delete('/market/cart/:itemId', removeFromCartHandler);
router.post('/market/cart/checkout', checkoutCartHandler);

router.use(requireStoreCreator);

// Inventory CRUD
router.get('/inventory', getInventoryHandler);
router.get('/inventory/:id', getItemHandler);
router.post('/inventory', upload.single('asset'), createItemHandler);
router.post('/inventory/import-excel', upload.single('excel'), importExcelHandler);
router.put('/inventory/:id', updateItemHandler);
router.delete('/inventory/:id', deleteItemHandler);

// Revenue & Stats
router.get('/overview', getOverviewHandler);
router.get('/revenue', getRevenueHandler);

// Apriori & Combos
router.get('/apriori', runAprioriHandler);
router.get('/combos', getCombosHandler);
router.post('/combos', saveComboHandler);

// Dataset loading
router.post('/datasets/load', loadDatasetHandler);

export default router;
