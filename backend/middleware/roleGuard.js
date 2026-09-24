/**
 * Role-based access control middleware.
 * Usage: router.get('/admin/...', authMiddleware, roleGuard('admin', 'super_admin'), handler)
 */
function roleGuard(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        error: 'Forbidden',
        message: `Role '${req.user.role}' is not authorized. Required: ${allowedRoles.join(', ')}`,
      });
    }

    next();
  };
}

module.exports = { roleGuard };
