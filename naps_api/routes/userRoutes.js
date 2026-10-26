const express = require('express');
const { getUsers, createUser, updateUser } = require('../controllers/userController');
const { tokenVerification, requireRoles } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(tokenVerification);
router.get('/', getUsers);
router.post('/', requireRoles('admin', 'supervisor'), createUser);
router.patch('/:id', requireRoles('admin', 'supervisor'), updateUser);

module.exports = router;
