import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/theme_provider.dart';
import '../core/models/event_model.dart';
import '../core/services/calendar_api_service.dart';
import '../core/services/api_client.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';
import '../providers/auth_provider.dart';


class CalendarPopup extends StatefulWidget {
  const CalendarPopup({super.key});

  @override
  State<CalendarPopup> createState() => _CalendarPopupState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CalendarPopup(),
    );
  }
}

class _CalendarPopupState extends State<CalendarPopup> {
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;
  Map<DateTime, List<EventModel>> _events = {};
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    print('[Calendar] Using API: ${ApiClient.getBaseUrl()}/api/events');
    _fetchEvents();
  }

  String? get _accessToken {
    try {
      return context.read<AuthProvider>().accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchEvents() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final token = _accessToken;
      print('[Calendar] Token from AuthProvider: ${token != null ? "${token.substring(0, 15)}..." : "NULL"}');
      final events = await CalendarApiService.fetchEvents(accessToken: token);
      final Map<DateTime, List<EventModel>> grouped = {};
      for (var e in events) {
        final localDate = e.date.toLocal();
        final d = DateTime.utc(localDate.year, localDate.month, localDate.day);
        if (grouped[d] == null) grouped[d] = [];
        grouped[d]!.add(e);
      }
      if (mounted) {
        setState(() {
          _events = grouped;
          _isLoading = false;
          if (events.isEmpty) {
            _errorMsg = 'API: ${ApiClient.getBaseUrl()}/api/events\nToken: ${token != null ? "Có" : "KHÔNG CÓ"}\nKhông có dữ liệu trả về.';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMsg = 'Lỗi tải lịch: $e'; });
    }
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    // TableCalendar passes `day` in UTC
    final d = DateTime.utc(day.year, day.month, day.day);
    return _events[d] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.of(context).bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppTheme.of(context).primaryGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch Của Bạn',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.palette, color: Colors.white),
                      tooltip: 'Đổi chủ đề',
                      onPressed: () => _showThemeSwitcher(context),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
                ? Center(child: const CustomLoading(size: 80))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        TableCalendar<EventModel>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          eventLoader: _getEventsForDay,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          holidayPredicate: (day) {
                            return _getEventsForDay(day).any((e) => e.type == 'holiday');
                          },
                          calendarStyle: CalendarStyle(
                            holidayTextStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            selectedDecoration: BoxDecoration(
                              color: AppTheme.of(context).primary,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppTheme.of(context).primary.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(), // Disable default marker
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, day, events) {
                              if (events.isEmpty) return const SizedBox();
                              
                              final hasHoliday = events.any((e) => e.type == 'holiday');
                              final hasNote = events.any((e) => e.type != 'holiday');
                              
                              return Positioned(
                                bottom: 6,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasHoliday)
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    if (hasNote)
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.of(context).primary,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Note ngày ${DateFormat('dd/MM/yyyy').format(_selectedDay ?? _focusedDay)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.of(context).textDark,
                                  fontSize: 16,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showAddNoteDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.of(context).primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Thêm'),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (selectedEvents.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(
                                  'Không có sự kiện nào trong ngày.',
                                  style: TextStyle(color: AppTheme.of(context).textMuted),
                                ),
                                if (_errorMsg != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: Text(
                                      _errorMsg!,
                                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: selectedEvents.length,
                            itemBuilder: (context, index) {
                              final event = selectedEvents[index];
                              final isHoliday = event.type == 'holiday';
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.of(context).card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.of(context).divider),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    isHoliday ? Icons.celebration : Icons.event_note,
                                    color: isHoliday ? Colors.redAccent : AppTheme.of(context).primary,
                                  ),
                                  title: Text(
                                    event.title,
                                    style: TextStyle(
                                      fontWeight: isHoliday ? FontWeight.bold : FontWeight.w600,
                                      color: isHoliday ? Colors.redAccent : AppTheme.of(context).textDark,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isHoliday 
                                      ? 'Ngày lễ' 
                                      : (event.note != null && event.note!.isNotEmpty 
                                          ? event.note! 
                                          : 'Cá nhân'), 
                                    style: TextStyle(fontSize: 12, color: AppTheme.of(context).textMuted)
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm ghi chú', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'Tiêu đề (ví dụ: Tặng quà sinh nhật)...',
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.of(context).primary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nội dung chi tiết...',
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.of(context).primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: AppTheme.of(context).textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty && noteCtrl.text.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tiêu đề hoặc nội dung'))
                );
                return;
              }
              final titleTxt = titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Ghi chú';
              final noteTxt = noteCtrl.text;
              Navigator.pop(ctx);
              
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Đang lưu ghi chú...'), duration: Duration(seconds: 2))
              );
              
              final result = await CalendarApiService.createEvent(
                title: titleTxt, 
                note: noteTxt,
                date: _selectedDay ?? _focusedDay,
                accessToken: _accessToken,
              );
              
              if (result['success'] == true) {
                _fetchEvents();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('✅ Ghi chú đã được lưu thành công!'))
                );
              } else {
                final errorMsg = result['error'] ?? 'Lỗi không xác định';
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('❌ $errorMsg'),
                    duration: const Duration(seconds: 5),
                    backgroundColor: Colors.red.shade700,
                  )
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.of(context).primary),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showThemeSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final currentTheme = themeProvider.currentTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chủ đề hệ thống', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Chỉ admin có quyền đổi theme trong trang quản trị.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.phone_android, color: Colors.teal),
                  title: const Text('Mặc định'),
                  trailing: currentTheme == AppThemeType.defaultTheme
                      ? Icon(Icons.check_circle, color: AppTheme.of(context).primary)
                      : const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
                ),
                ListTile(
                  leading: const Icon(Icons.celebration, color: Colors.red),
                  title: const Text('Tết Nguyên Đán'),
                  trailing: currentTheme == AppThemeType.tet
                      ? Icon(Icons.check_circle, color: AppTheme.of(context).primary)
                      : const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.pink),
                  title: const Text('Valentine'),
                  trailing: currentTheme == AppThemeType.valentine
                      ? Icon(Icons.check_circle, color: AppTheme.of(context).primary)
                      : const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
