const Task = require('../models/taskModel');
const User = require('../models/userModel');

const canManage = (user) => user.role === 'admin' || user.role === 'supervisor';

exports.getTasks = async (req, res, next) => {
  try {
    const filter = { organization: req.user.organization };
    if (req.user.role === 'employee') filter.assignedTo = req.user.id;
    if (req.query.status) filter.status = req.query.status;
    const tasks = await Task.find(filter).populate('assignedTo', 'name email').populate('createdBy', 'name').sort({ dueDate: 1, createdAt: -1 });
    return res.json(tasks);
  } catch (err) { next(err); }
};

exports.createTask = async (req, res, next) => {
  try {
    const assignedTo = canManage(req.user) ? req.body.assignedTo || req.user.id : req.user.id;
    const assignee = await User.findOne({ _id: assignedTo, organization: req.user.organization, active: true });
    if (!assignee) return res.status(400).json({ message: 'choose an active team member' });
    const task = await Task.create({ organization: req.user.organization, title: req.body.title, details: req.body.details ?? '', branch: canManage(req.user) ? req.body.branch || req.user.branch : req.user.branch, assignedTo: assignee.id, createdBy: req.user.id, dueDate: req.body.dueDate, status: 'open' });
    await task.populate(['assignedTo', 'createdBy']);
    return res.status(201).json(task);
  } catch (err) { next(err); }
};

exports.updateTask = async (req, res, next) => {
  try {
    const task = await Task.findOne({ _id: req.params.id, organization: req.user.organization });
    if (!task) return res.status(404).json({ message: 'task not found' });
    if (!canManage(req.user) && task.assignedTo.toString() !== req.user.id) return res.status(403).json({ message: 'you can only update tasks assigned to you' });
    if (req.body.status !== undefined && !['open', 'inProgress', 'complete'].includes(req.body.status)) return res.status(400).json({ message: 'choose a valid task status' });
    if (req.body.status && ['open', 'inProgress', 'complete'].includes(req.body.status)) task.status = req.body.status;
    if (canManage(req.user)) {
      if (req.body.title !== undefined) task.title = req.body.title;
      if (req.body.details !== undefined) task.details = req.body.details;
      if (req.body.dueDate !== undefined) task.dueDate = req.body.dueDate;
      if (req.body.assignedTo !== undefined) {
        const assignee = await User.findOne({ _id: req.body.assignedTo, organization: req.user.organization, active: true });
        if (!assignee) return res.status(400).json({ message: 'choose an active team member' });
        task.assignedTo = assignee.id;
      }
    }
    await task.save();
    await task.populate(['assignedTo', 'createdBy']);
    return res.json(task);
  } catch (err) { next(err); }
};

exports.deleteTask = async (req, res, next) => {
  try {
    if (!canManage(req.user)) return res.status(403).json({ message: 'only supervisors can remove a task' });
    const task = await Task.findOneAndDelete({ _id: req.params.id, organization: req.user.organization });
    if (!task) return res.status(404).json({ message: 'task not found' });
    return res.json({ message: 'task removed' });
  } catch (err) { next(err); }
};
