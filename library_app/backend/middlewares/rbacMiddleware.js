// Role-Based Access Control (RBAC) Middleware

const ROLE_HIERARCHY = {
  super_admin: 3,
  admin: 2,
  student: 1
};

/**
 * Check if user has minimum required role level
 */
export const requireRole = (minRole) => {
  return (req, res, next) => {
    const userRole = req.user.role;
    const userLevel = ROLE_HIERARCHY[userRole] || 0;
    const requiredLevel = ROLE_HIERARCHY[minRole] || 0;

    if (userLevel < requiredLevel) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }
    next();
  };
};

/**
 * Super Admin only
 */
export const superAdminOnly = (req, res, next) => {
  if (req.user.role !== 'super_admin') {
    return res.status(403).json({
      success: false,
      message: 'Super Admin access required'
    });
  }
  next();
};

/**
 * Admin or higher (admin, super_admin)
 */
export const adminOrHigher = (req, res, next) => {
  const userRole = req.user.role;
  if (userRole !== 'admin' && userRole !== 'super_admin') {
    return res.status(403).json({
      success: false,
      message: 'Admin access required'
    });
  }
  next();
};

/**
 * Check if user can manage target user
 * Super Admin can manage everyone except other super admins
 * Admin cannot manage super admins
 */
export const canManageUser = (targetRole) => {
  return (req, res, next) => {
    const userRole = req.user.role;
    const userLevel = ROLE_HIERARCHY[userRole] || 0;
    const targetLevel = ROLE_HIERARCHY[targetRole] || 0;

    // Cannot manage users at same or higher level
    if (userLevel <= targetLevel) {
      return res.status(403).json({
        success: false,
        message: 'Cannot manage users at same or higher privilege level'
      });
    }
    next();
  };
};
