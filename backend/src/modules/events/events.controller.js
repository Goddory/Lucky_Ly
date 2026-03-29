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

let holidayCache = { year: null, data: [] };

export const listEvents = async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const events = await eventsService.getUserEvents(userId);

        try {
            const currentYear = new Date().getFullYear();
            if (holidayCache.year !== currentYear) {
                const fetchModule = await import('node-fetch').catch(() => null);
                const fetchFn = fetchModule ? fetchModule.default : global.fetch;
                
                const holidayRes = await fetchFn(`https://date.nager.at/api/v3/PublicHolidays/${currentYear}/VN`);
                if (holidayRes.ok) {
                    const holidays = await holidayRes.json();
                    holidayCache.data = holidays.map(h => ({
                        id: `holiday_${h.date}`,
                        title: h.localName || h.name,
                        date: new Date(h.date).toISOString(),
                        type: 'holiday',
                        note: 'Ngày lễ quốc gia'
                    }));
                    holidayCache.year = currentYear;
                }
            }
            return res.status(200).json([...events, ...holidayCache.data]);
        } catch (fetchErr) {
            console.error('Lỗi khi fetch ngày lễ:', fetchErr);
        }

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
