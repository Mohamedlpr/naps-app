const Announcement = require('../models/announcementModel');

exports.getAnnouncements = async (req, res, next) => {
  try {
    const announcements = await Announcement.find({ organization: req.user.organization }).populate('createdBy', 'name').sort({ createdAt: -1 });
    return res.json(announcements);
  } catch (err) { next(err); }
};

exports.createAnnouncement = async (req, res, next) => {
  try {
    const announcement = await Announcement.create({ organization: req.user.organization, title: req.body.title, message: req.body.message, branch: req.body.branch || req.user.branch, createdBy: req.user.id });
    await announcement.populate('createdBy', 'name');
    return res.status(201).json(announcement);
  } catch (err) { next(err); }
};

exports.acknowledgeAnnouncement = async (req, res, next) => {
  try {
    const announcement = await Announcement.findOneAndUpdate(
      { _id: req.params.id, organization: req.user.organization },
      { $addToSet: { acknowledgedBy: { user: req.user.id, acknowledgedAt: new Date() } } },
      { new: true, runValidators: true },
    ).populate('createdBy', 'name');
    if (!announcement) return res.status(404).json({ message: 'announcement not found' });
    return res.json(announcement);
  } catch (err) { next(err); }
};

exports.deleteAnnouncement = async (req, res, next) => {
  try {
    const announcement = await Announcement.findOneAndDelete({ _id: req.params.id, organization: req.user.organization });
    if (!announcement) return res.status(404).json({ message: 'announcement not found' });
    return res.json({ message: 'announcement removed' });
  } catch (err) { next(err); }
};
