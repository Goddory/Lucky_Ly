import * as eventsService from './events.service.js';

export const createEvent = async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const { title, date, type, note } = req.body;

        if (!title || !date) {
            return res.status(400).json({ message: 'Title and date are required.' });
        }

        const event = await eventsService.createEvent(userId, { title, date, type: type || 'personal_note', note });
        res.status(201).json({
            message: 'Event created successfully',
            event
        });
    } catch (error) {
        next(error);
    }
};

export const listEvents = async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const events = await eventsService.getUserEvents(userId);
        res.status(200).json(events);
    } catch (error) {
        next(error);
    }
};

export const removeEvent = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const deletedEvent = await eventsService.deleteEvent(id, userId);

        if (!deletedEvent) {
            return res.status(404).json({ message: 'Event not found or unauthorized.' });
        }

        res.status(200).json({ message: 'Event deleted successfully' });
    } catch (error) {
        next(error);
    }
};
