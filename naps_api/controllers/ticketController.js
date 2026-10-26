const Ticket = require('../models/ticketModel');
const User = require('../models/userModel');

exports.getTickets = async (req, res, next) => {
  try {
    const filter = { organization: req.user.organization };
    if (req.query.status) filter.status = req.query.status;
    const tickets = await Ticket.find(filter).populate('createdBy', 'name email').populate('assignedTo', 'name').sort({ createdAt: -1 });
    return res.json(tickets);
  } catch (err) { next(err); }
};

exports.createTicket = async (req, res, next) => {
  try {
    const ticket = await Ticket.create({ organization: req.user.organization, title: req.body.title, details: req.body.details ?? '', department: req.body.department, branch: req.user.branch, createdBy: req.user.id, status: 'open' });
    await ticket.populate('createdBy', 'name email');
    return res.status(201).json(ticket);
  } catch (err) { next(err); }
};

exports.updateTicket = async (req, res, next) => {
  try {
    const ticket = await Ticket.findOne({ _id: req.params.id, organization: req.user.organization });
    if (!ticket) return res.status(404).json({ message: 'support request not found' });
    if (req.user.role === 'employee' && ticket.createdBy.toString() !== req.user.id) return res.status(403).json({ message: 'you can only update requests you submitted' });
    if (req.body.status !== undefined && !['open', 'progress', 'resolved'].includes(req.body.status)) return res.status(400).json({ message: 'choose a valid request status' });
    if (req.body.status && ['open', 'progress', 'resolved'].includes(req.body.status)) {
      if (req.user.role === 'employee' && req.body.status !== 'resolved') return res.status(403).json({ message: 'only supervisors can change the processing status' });
      ticket.status = req.body.status;
    }
    if (req.user.role !== 'employee' && req.body.assignedTo !== undefined) {
      if (!req.body.assignedTo) ticket.assignedTo = null;
      else {
        const assignee = await User.findOne({ _id: req.body.assignedTo, organization: req.user.organization, active: true });
        if (!assignee) return res.status(400).json({ message: 'choose an active team member' });
        ticket.assignedTo = assignee.id;
      }
    }
    await ticket.save();
    await ticket.populate(['createdBy', 'assignedTo']);
    return res.json(ticket);
  } catch (err) { next(err); }
};

exports.deleteTicket = async (req, res, next) => {
  try {
    const filter = { _id: req.params.id, organization: req.user.organization };
    if (req.user.role === 'employee') filter.createdBy = req.user.id;
    const ticket = await Ticket.findOneAndDelete(filter);
    if (!ticket) return res.status(404).json({ message: 'support request not found' });
    return res.json({ message: 'support request removed' });
  } catch (err) { next(err); }
};
