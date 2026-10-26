const express = require('express');
const { getAnnouncements, createAnnouncement, acknowledgeAnnouncement, deleteAnnouncement } = require('../controllers/announcementController');
const { tokenVerification, requireRoles } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(tokenVerification);
router.get('/', getAnnouncements);
router.post('/', requireRoles('admin', 'supervisor'), createAnnouncement);
router.post('/:id/acknowledge', acknowledgeAnnouncement);
router.delete('/:id', requireRoles('admin'), deleteAnnouncement);

module.exports = router;
