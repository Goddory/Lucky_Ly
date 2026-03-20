export const activityLogger = (req, res, next) => {
    const start = Date.now();
    const { method, originalUrl, ip, body } = req;
    
    // Determine action type based on route
    let action = 'System Request';
    let module = 'SYSTEM';
    let details = '';
    
    // Cố gắng định danh người dùng từ token (nếu có middleware requireAuth chạy trước đó)
    // Hoặc giả định là Khách nếu không có req.user
    const userIdentifier = req.user?.email || req.user?.id || req.user?.username || 'Khách/Chưa ĐN';
    
    if (originalUrl.includes('/api/auth/login')) {
        action = 'Người dùng đăng nhập'; module = 'AUTH';
        details = `Tài khoản: ${body.login || body.email || 'N/A'}`;
    } else if (originalUrl.includes('/api/auth/google')) {
        action = 'Đăng nhập (Google)'; module = 'AUTH';
        details = 'OAuth SignIn';
    } else if (originalUrl.includes('/api/auth/facebook')) {
        action = 'Đăng nhập (Facebook)'; module = 'AUTH';
        details = `Email FB: ${body.email || 'N/A'}`;
    } else if (originalUrl.includes('/api/auth/register')) {
        action = 'Đăng ký tài khoản mới'; module = 'AUTH';
        details = `Email ĐK: ${body.email || 'N/A'}`;
    } else if (originalUrl.includes('/api/auth/logout')) {
        action = 'Người dùng đăng xuất'; module = 'AUTH';
    } else if (originalUrl.includes('/api/sync/push')) {
        action = 'Hệ thống/Người dùng đẩy thông tin lên Cloud'; module = 'SYNC';
        const numRecords = body.records?.length || 0;
        details = `Số lượng bản ghi vừa đồng bộ: ${numRecords}`;
    } else if (originalUrl.includes('/api/sync/pull')) {
        action = 'Hệ thống/Người dùng tải dữ liệu từ Cloud'; module = 'SYNC';
    } else if (originalUrl.includes('/api/designs')) {
        action = 'Người dùng thay đổi Dữ liệu Thiết kế (Designs)'; module = 'DATA';
        details = method !== 'GET' ? `Có sự thay đổi dữ liệu` : 'Chỉ xem dữ liệu';
    } else if (originalUrl.includes('/api/users')) {
        action = 'Tác động Dữ liệu Người dùng'; module = 'USER';
    }
    
    // Intercept finish to log status and time
    res.on('finish', () => {
        const duration = Date.now() - start;
        const status = res.statusCode;
        const time = new Date().toLocaleString('vi-VN');
        
        const detailSuffix = details ? ` | Chi tiết: [${details}]` : '';
        const userSuffix = ` | User: [${userIdentifier}]`;
        
        let logMsg = `[${time}] [${module}] ${action}${detailSuffix}${userSuffix} | ${method} ${originalUrl} | Status: ${status} | IP: ${ip} | ${duration}ms`;
        
        if (status >= 400 && status < 500) {
            console.warn(`⚠️  ${logMsg}`);
        } else if (status >= 500) {
            console.error(`❌  ${logMsg}`);
        } else {
            console.log(`🟢  ${logMsg}`);
        }
    });
    
    next();
};
