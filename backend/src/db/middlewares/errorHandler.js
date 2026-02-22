// Middleware xử lý route không tồn tại, trả về HTTP 404.
export function notFoundHandler(req, res) {
  res.status(404).json({ message: 'Endpoint not found' });
}

// Middleware xử lý lỗi tổng, chuẩn hóa response lỗi và ẩn chi tiết lỗi hệ thống.
export function errorHandler(err, req, res, next) {
  if (res.headersSent) {
    return next(err);
  }

  const status = err.statusCode || 500;
  const message = status >= 500 ? 'Internal server error' : err.message;

  if (status >= 500) {
    console.error(err);
  }

  res.status(status).json({ message });
}
