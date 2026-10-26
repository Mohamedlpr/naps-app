const express = require('express');
const { getTasks, createTask, updateTask, deleteTask } = require('../controllers/taskController');
const { tokenVerification, requireRoles } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(tokenVerification);
router.get('/', getTasks);
router.post('/', createTask);
router.patch('/:id', updateTask);
router.delete('/:id', requireRoles('admin', 'supervisor'), deleteTask);

module.exports = router;
