const express = require('express');
const { bootstrapOrganization, login, getSession, changePassword } = require('../controllers/authController');
const { tokenVerification } = require('../middleware/authMiddleware');
const { authRequestLimit } = require('../middleware/requestLimitMiddleware');

const router = express.Router();

router.post('/bootstrap', authRequestLimit, bootstrapOrganization);
router.post('/login', authRequestLimit, login);
router.get('/me', tokenVerification, getSession);
router.post('/password', tokenVerification, changePassword);

module.exports = router;
