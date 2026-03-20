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
  // Show actual error message during debugging
  const message =
    process.env.NODE_ENV === 'development' || status < 500
      ? `[API_ERR] ${err.message || 'Internal server error'}`
      : 'Internal server error';

  if (status >= 500) {
    console.error(err);
  }

  res.status(status).json({ message });
}
