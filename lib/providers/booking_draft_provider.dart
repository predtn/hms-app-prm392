import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/customer_short_detail.dart';

class BookingDraft {
  BookingDraft({
    this.guestName = '',
    this.phone = '',
    this.isNewCustomer = true,
    this.selectedCustomer,
    this.checkIn,
    this.checkOut,
    this.checkInNow = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String guestName;
  String phone;
  bool isNewCustomer;
  CustomerShortDetail? selectedCustomer;
  DateTime? checkIn;
  DateTime? checkOut;
  bool checkInNow;
  DateTime updatedAt;

  void touch() {
    updatedAt = DateTime.now();
  }
}

class BookingDraftProvider extends ChangeNotifier {
  BookingDraftProvider({Duration draftTtl = const Duration(minutes: 30)})
    : _draftTtl = draftTtl;

  final Duration _draftTtl;
  final Map<String, BookingDraft> _drafts = {};

  static String singleRoomKey(int roomId) => 'single:$roomId';

  static String manyRoomsKey(Iterable<int> roomIds) {
    final sortedIds = roomIds.toList()..sort();
    return 'many:${sortedIds.join(',')}';
  }

  BookingDraft getDraft(String key) {
    _removeIfExpired(key);
    return _drafts.putIfAbsent(key, BookingDraft.new);
  }

  void initializeDraft(String key, {DateTime? checkIn, DateTime? checkOut}) {
    final draft = getDraft(key);
    var changed = false;

    if (draft.checkIn == null && checkIn != null) {
      draft.checkIn = checkIn;
      draft.touch();
      changed = true;
    }

    if (draft.checkOut == null && checkOut != null) {
      draft.checkOut = checkOut;
      draft.touch();
      changed = true;
    }

    if (changed) notifyListeners();
  }

  void setGuestName(String key, String guestName) {
    final draft = getDraft(key);
    if (draft.guestName == guestName) return;
    draft.guestName = guestName;
    draft.touch();
    notifyListeners();
  }

  void setPhone(String key, String phone) {
    final draft = getDraft(key);
    if (draft.phone == phone) return;
    draft.phone = phone;
    draft.touch();
    notifyListeners();
  }

  void setIsNewCustomer(String key, bool isNewCustomer) {
    final draft = getDraft(key);
    if (draft.isNewCustomer == isNewCustomer) return;
    draft.isNewCustomer = isNewCustomer;
    draft.touch();
    notifyListeners();
  }

  void setSelectedCustomer(String key, CustomerShortDetail? selectedCustomer) {
    final draft = getDraft(key);
    if (draft.selectedCustomer == selectedCustomer) return;
    draft.selectedCustomer = selectedCustomer;
    draft.touch();
    notifyListeners();
  }

  void setCheckIn(String key, DateTime? checkIn) {
    final draft = getDraft(key);
    if (draft.checkIn == checkIn) return;
    draft.checkIn = checkIn;
    draft.touch();
    notifyListeners();
  }

  void setCheckOut(String key, DateTime? checkOut) {
    final draft = getDraft(key);
    if (draft.checkOut == checkOut) return;
    draft.checkOut = checkOut;
    draft.touch();
    notifyListeners();
  }

  void setCheckInNow(String key, bool checkInNow) {
    final draft = getDraft(key);
    if (draft.checkInNow == checkInNow) return;
    draft.checkInNow = checkInNow;
    if (checkInNow) {
      draft.checkIn = DateTime.now();
    }
    draft.touch();
    notifyListeners();
  }

  void clearDraft(String key) {
    if (_drafts.remove(key) != null) {
      notifyListeners();
    }
  }

  void clearExpiredDrafts() {
    final expiredKeys = _drafts.entries
        .where((entry) => _isExpired(entry.value))
        .map((entry) => entry.key)
        .toList();

    if (expiredKeys.isEmpty) return;

    for (final key in expiredKeys) {
      _drafts.remove(key);
    }
    notifyListeners();
  }

  bool _isExpired(BookingDraft draft) {
    return DateTime.now().difference(draft.updatedAt) > _draftTtl;
  }

  void _removeIfExpired(String key) {
    final draft = _drafts[key];
    if (draft != null && _isExpired(draft)) {
      _drafts.remove(key);
    }
  }
}
