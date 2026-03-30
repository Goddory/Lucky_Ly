# Lucky Ly Mobile - Function Comments (lib)

Tai lieu nay comment chuc nang cua cac ham trong thu muc lib.
Tong so file Dart: 56
Ngay tao: 2026-03-30 10:53:18

## lib\app_theme.dart
- getTheme (line 12): Lay du lieu tu API, storage hoac database.
- of (line 23): Xu ly nghiep vu theo ngu canh cua file/module.
- glowShadow (line 108): Xu ly nghiep vu theo ngu canh cua file/module.
- glass (line 117): Xu ly nghiep vu theo ngu canh cua file/module.
- createState (line 134): Tao moi va luu du lieu.
- initState (line 142): Khoi tao du lieu, listener hoac config ban dau.
- dispose (line 154): Giai phong tai nguyen, controller, stream/listener.
- build (line 160): Dung de xay dung UI widget theo state hien tai.

## lib\celebrate_screen.dart
- build (line 9): Dung de xay dung UI widget theo state hien tai.
- _buildHolidayCard (line 68): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\core\database\database_helper.dart
- _initDB (line 24): Xu ly nghiep vu theo ngu canh cua file/module.
- _initializeDatabaseFactoryIfNeeded (line 48): Xu ly nghiep vu theo ngu canh cua file/module.
- _createDB (line 59): Xu ly nghiep vu theo ngu canh cua file/module.
- _ensureLocalTables (line 98): Xu ly nghiep vu theo ngu canh cua file/module.
- _getTableColumns (line 115): Xu ly nghiep vu theo ngu canh cua file/module.
- insertAvatar (line 143): Tao moi va luu du lieu.
- insertUser (line 216): Tao moi va luu du lieu.
- insertDesign (line 257): Tao moi va luu du lieu.
- close (line 267): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\core\models\event_model.dart
- toJson (line 47): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\core\services\api_client.dart
- updateToken (line 11): Cap nhat du lieu/trang thai hien co.
- get (line 20): Lay du lieu tu API, storage hoac database.
- post (line 26): Xu ly nghiep vu theo ngu canh cua file/module.
- put (line 32): Xu ly nghiep vu theo ngu canh cua file/module.
- patch (line 38): Xu ly nghiep vu theo ngu canh cua file/module.
- delete (line 44): Xoa du lieu hoac loai bo phan tu.
- getBaseUrl (line 50): Lay du lieu tu API, storage hoac database.

## lib\core\services\calendar_api_service.dart
- _getToken (line 10): Xu ly nghiep vu theo ngu canh cua file/module.
- fetchEvents (line 19): Lay du lieu tu API, storage hoac database.

## lib\core\services\database_helper.dart
- markAsSynced (line 12): Cap nhat du lieu/trang thai hien co.
- insertAvatar (line 14): Tao moi va luu du lieu.
- insertUser (line 16): Tao moi va luu du lieu.
- insertDesign (line 18): Tao moi va luu du lieu.

## lib\core\services\socket_service.dart
- connect (line 11): Quan ly ket noi realtime/socket va room.
- disconnect (line 40): Quan ly ket noi realtime/socket va room.
- joinRoom (line 48): Quan ly ket noi realtime/socket va room.
- leaveRoom (line 52): Quan ly ket noi realtime/socket va room.
- sendMessage (line 57): Gui su kien hoac dang ky/huy listener su kien.
- markRead (line 61): Cap nhat du lieu/trang thai hien co.
- sendTyping (line 65): Gui su kien hoac dang ky/huy listener su kien.
- stopTyping (line 69): Xu ly nghiep vu theo ngu canh cua file/module.
- onMessage (line 74): Gui su kien hoac dang ky/huy listener su kien.
- offMessage (line 78): Gui su kien hoac dang ky/huy listener su kien.
- onNotification (line 82): Gui su kien hoac dang ky/huy listener su kien.
- offNotification (line 86): Gui su kien hoac dang ky/huy listener su kien.
- onTyping (line 90): Gui su kien hoac dang ky/huy listener su kien.
- onStopTyping (line 94): Gui su kien hoac dang ky/huy listener su kien.
- onRead (line 98): Gui su kien hoac dang ky/huy listener su kien.

## lib\core\services\sync_manager.dart
- _pushTable (line 11): Xu ly nghiep vu theo ngu canh cua file/module.
- pushData (line 44): Dong bo du lieu giua local va backend.
- pullData (line 52): Dong bo du lieu giua local va backend.
- manualSync (line 111): Dong bo du lieu giua local va backend.

## lib\data\gift_catalog.dart
- getModels (line 71): Lay du lieu tu API, storage hoac database.
- getStickers (line 75): Lay du lieu tu API, storage hoac database.

## lib\design_selection_screen.dart
- build (line 14): Dung de xay dung UI widget theo state hien tai.

## lib\gift_center_screen.dart
- build (line 10): Dung de xay dung UI widget theo state hien tai.

## lib\history_screen.dart
- createState (line 10): Tao moi va luu du lieu.
- initState (line 19): Khoi tao du lieu, listener hoac config ban dau.
- _fetchHistory (line 24): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 33): Dung de xay dung UI widget theo state hien tai.
- _buildEmptyState (line 67): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildFilterBar (line 80): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildFilterChip (line 93): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildTransactionItem (line 119): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\home_screen.dart
- createState (line 46): Tao moi va luu du lieu.
- initState (line 55): Khoi tao du lieu, listener hoac config ban dau.
- _showNotificationSnackbar (line 94): Xu ly nghiep vu theo ngu canh cua file/module.
- _getNotificationIcon (line 122): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleNotificationTap (line 132): Xu ly nghiep vu theo ngu canh cua file/module.
- _saveTokenToPrefs (line 144): Xu ly nghiep vu theo ngu canh cua file/module.
- _isMarketingAdmin (line 169): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildWelcomeHeader (line 174): Xu ly nghiep vu theo ngu canh cua file/module.
- dispose (line 215): Giai phong tai nguyen, controller, stream/listener.
- build (line 221): Dung de xay dung UI widget theo state hien tai.
- _buildSliverHeader (line 263): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildThemeDecorations (line 366): Xu ly logic chu de va style giao dien.
- _buildQuickActions (line 408): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildWalletCard (line 445): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildPremiumServiceGrid (line 491): Xu ly nghiep vu theo ngu canh cua file/module.
- _showNotificationOverlay (line 543): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildEventsSection (line 618): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildBottomNav (line 735): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildQrFab (line 767): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleCameraAccess (line 792): Xu ly nghiep vu theo ngu canh cua file/module.
- _showSimpleMessage (line 827): Xu ly nghiep vu theo ngu canh cua file/module.
- createState (line 838): Tao moi va luu du lieu.
- initState (line 846): Khoi tao du lieu, listener hoac config ban dau.
- _initCamera (line 851): Xu ly nghiep vu theo ngu canh cua file/module.
- _toggleCamera (line 861): Xu ly nghiep vu theo ngu canh cua file/module.
- dispose (line 868): Giai phong tai nguyen, controller, stream/listener.
- build (line 874): Dung de xay dung UI widget theo state hien tai.
- build (line 936): Dung de xay dung UI widget theo state hien tai.
- build (line 989): Dung de xay dung UI widget theo state hien tai.
- createState (line 1056): Tao moi va luu du lieu.
- initState (line 1063): Khoi tao du lieu, listener hoac config ban dau.
- dispose (line 1072): Giai phong tai nguyen, controller, stream/listener.
- build (line 1078): Dung de xay dung UI widget theo state hien tai.
- build (line 1106): Dung de xay dung UI widget theo state hien tai.
- build (line 1156): Dung de xay dung UI widget theo state hien tai.
- build (line 1181): Dung de xay dung UI widget theo state hien tai.
- build (line 1240): Dung de xay dung UI widget theo state hien tai.

## lib\main.dart
- main (line 30): Entry point khoi chay ung dung.
- build (line 112): Dung de xay dung UI widget theo state hien tai.
- build (line 135): Dung de xay dung UI widget theo state hien tai.
- createState (line 145): Tao moi va luu du lieu.
- initState (line 193): Khoi tao du lieu, listener hoac config ban dau.
- dispose (line 215): Giai phong tai nguyen, controller, stream/listener.
- _initDeepLinks (line 226): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleDeepLink (line 241): Xu ly nghiep vu theo ngu canh cua file/module.
- _loadSavedAccounts (line 251): Xu ly nghiep vu theo ngu canh cua file/module.
- _saveAccount (line 276): Xu ly nghiep vu theo ngu canh cua file/module.
- _initDeviceId (line 298): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildDeviceInfo (line 311): Xu ly nghiep vu theo ngu canh cua file/module.
- _tryAutoLoginFromSavedSession (line 413): Xu ly xac thuc, phien dang nhap va token.
- _removeAccount (line 461): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 474): Dung de xay dung UI widget theo state hien tai.
- _buildSignUpForm (line 679): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildSignInForm (line 800): Xu ly nghiep vu theo ngu canh cua file/module.
- _showSavedAccountsSheet (line 873): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleSubmit (line 1011): Xu ly nghiep vu theo ngu canh cua file/module.
- _submitSignUp (line 1021): Xu ly nghiep vu theo ngu canh cua file/module.
- _submitSignIn (line 1082): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleFacebookLogin (line 1128): Xu ly xac thuc, phien dang nhap va token.
- _ensureGoogleSignInInitialized (line 1191): Xu ly nghiep vu theo ngu canh cua file/module.
- _isGoogleLoginCancelled (line 1203): Xu ly xac thuc, phien dang nhap va token.
- _googleErrorMessage (line 1211): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleGoogleLogin (line 1228): Xu ly xac thuc, phien dang nhap va token.
- _showForgotPasswordSheet (line 1295): Xu ly nghiep vu theo ngu canh cua file/module.
- buildStepContent (line 1315): Dung de xay dung UI widget theo state hien tai.
- _navigateToHome (line 1606): Xu ly nghiep vu theo ngu canh cua file/module.
- _looksLikeEmail (line 1642): Xu ly nghiep vu theo ngu canh cua file/module.
- _safeDecodeMap (line 1646): Xu ly/chuyen doi du lieu an toan.
- _showMessage (line 1653): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 1699): Dung de xay dung UI widget theo state hien tai.
- createState (line 1814): Tao moi va luu du lieu.
- initState (line 1823): Khoi tao du lieu, listener hoac config ban dau.
- dispose (line 1834): Giai phong tai nguyen, controller, stream/listener.
- build (line 1840): Dung de xay dung UI widget theo state hien tai.
- createState (line 1940): Tao moi va luu du lieu.
- initState (line 1949): Khoi tao du lieu, listener hoac config ban dau.
- dispose (line 1961): Giai phong tai nguyen, controller, stream/listener.
- build (line 1967): Dung de xay dung UI widget theo state hien tai.
- build (line 2042): Dung de xay dung UI widget theo state hien tai.

## lib\mobile_studio_screen.dart
- build (line 13): Dung de xay dung UI widget theo state hien tai.
- build (line 98): Dung de xay dung UI widget theo state hien tai.

## lib\money_transfer_screen.dart
- build (line 14): Dung de xay dung UI widget theo state hien tai.

## lib\offers_screen.dart
- createState (line 10): Tao moi va luu du lieu.
- initState (line 18): Khoi tao du lieu, listener hoac config ban dau.
- _fetchOffers (line 23): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 32): Dung de xay dung UI widget theo state hien tai.
- _buildEmptyState (line 55): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildOfferCard (line 68): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\payment_screen.dart
- build (line 17): Dung de xay dung UI widget theo state hien tai.
- build (line 108): Dung de xay dung UI widget theo state hien tai.
- _showMoMoPaymentBottomSheet (line 161): Xu ly nghiep vu theo ngu canh cua file/module.
- createState (line 175): Tao moi va luu du lieu.
- _createAndOpenMoMo (line 182): Xu ly nghiep vu theo ngu canh cua file/module.
- dispose (line 234): Giai phong tai nguyen, controller, stream/listener.
- build (line 240): Dung de xay dung UI widget theo state hien tai.
- _showVNPayBottomSheet (line 302): Xu ly nghiep vu theo ngu canh cua file/module.
- createState (line 316): Tao moi va luu du lieu.
- _createAndOpenVNPay (line 323): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 370): Dung de xay dung UI widget theo state hien tai.
- _showZaloPayBottomSheet (line 432): Xu ly nghiep vu theo ngu canh cua file/module.
- createState (line 446): Tao moi va luu du lieu.
- _createAndOpenZaloPay (line 453): Xu ly nghiep vu theo ngu canh cua file/module.
- dispose (line 506): Giai phong tai nguyen, controller, stream/listener.
- build (line 512): Dung de xay dung UI widget theo state hien tai.

## lib\profile_screen.dart
- createState (line 32): Tao moi va luu du lieu.
- initState (line 57): Khoi tao du lieu, listener hoac config ban dau.
- _resolveCurrentUserId (line 84): Xu ly nghiep vu theo ngu canh cua file/module.
- _loadLocalUser (line 90): Xu ly nghiep vu theo ngu canh cua file/module.
- dispose (line 111): Giai phong tai nguyen, controller, stream/listener.
- build (line 120): Dung de xay dung UI widget theo state hien tai.
- _buildPrivacySection (line 156): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildStaticHeader (line 196): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildProfileCard (line 307): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildInfoSection (line 410): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildSettingsSection (line 471): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildLogoutButton (line 584): Xu ly xac thuc, phien dang nhap va token.
- _buildDivider (line 625): Xu ly nghiep vu theo ngu canh cua file/module.
- _showThemeBottomSheet (line 629): Xu ly logic chu de va style giao dien.
- _showChangePasswordSheet (line 768): Xu ly nghiep vu theo ngu canh cua file/module.
- _saveProfile (line 980): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleLogout (line 1028): Xu ly xac thuc, phien dang nhap va token.
- _showSnack (line 1079): Xu ly nghiep vu theo ngu canh cua file/module.
- _getInitials (line 1101): Xu ly nghiep vu theo ngu canh cua file/module.
- _providerLabel (line 1109): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 1138): Dung de xay dung UI widget theo state hien tai.
- build (line 1229): Dung de xay dung UI widget theo state hien tai.

## lib\providers\auth_provider.dart
- _loadSession (line 26): Xu ly nghiep vu theo ngu canh cua file/module.
- updatePrivacy (line 52): Cap nhat du lieu/trang thai hien co.
- updateFcmToken (line 66): Cap nhat du lieu/trang thai hien co.
- fetchProfile (line 74): Lay du lieu tu API, storage hoac database.
- logout (line 88): Xu ly xac thuc, phien dang nhap va token.

## lib\providers\chat_provider.dart
- _initSocketListeners (line 23): Xu ly nghiep vu theo ngu canh cua file/module.
- fetchRooms (line 48): Lay du lieu tu API, storage hoac database.
- getMessages (line 62): Lay du lieu tu API, storage hoac database.
- fetchMessages (line 64): Lay du lieu tu API, storage hoac database.
- getOrCreateRoom (line 76): Lay du lieu tu API, storage hoac database.
- markAsRead (line 89): Cap nhat du lieu/trang thai hien co.

## lib\providers\friend_provider.dart
- fetchFriends (line 25): Lay du lieu tu API, storage hoac database.
- fetchSentRequests (line 39): Lay du lieu tu API, storage hoac database.
- fetchReceivedRequests (line 49): Lay du lieu tu API, storage hoac database.
- searchUsers (line 59): Xu ly nghiep vu theo ngu canh cua file/module.
- sendRequest (line 74): Gui su kien hoac dang ky/huy listener su kien.
- acceptRequest (line 103): Xu ly nghiep vu theo ngu canh cua file/module.
- declineRequest (line 129): Xu ly nghiep vu theo ngu canh cua file/module.
- unfriend (line 154): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\providers\store_provider.dart
- fetchInventory (line 24): Lay du lieu tu API, storage hoac database.
- fetchOverview (line 41): Lay du lieu tu API, storage hoac database.
- _setMockOverview (line 56): Xu ly nghiep vu theo ngu canh cua file/module.
- fetchRevenue (line 66): Lay du lieu tu API, storage hoac database.
- _setMockRevenue (line 81): Xu ly nghiep vu theo ngu canh cua file/module.
- fetchCombos (line 93): Lay du lieu tu API, storage hoac database.
- updateItem (line 157): Cap nhat du lieu/trang thai hien co.
- deleteItem (line 170): Xoa du lieu hoac loai bo phan tu.
- runApriori (line 184): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\providers\theme_provider.dart
- appThemeTypeFromApi (line 11): Xu ly logic chu de va style giao dien.
- appThemeTypeToApi (line 22): Xu ly logic chu de va style giao dien.
- _decodeMap (line 44): Xu ly/chuyen doi du lieu an toan.

## lib\screens\admin\admin_dashboard_screen.dart
- build (line 19): Dung de xay dung UI widget theo state hien tai.
- _buildHeroHeader (line 119): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\admin\customer_segments_screen.dart
- createState (line 20): Tao moi va luu du lieu.
- initState (line 28): Khoi tao du lieu, listener hoac config ban dau.
- _loadSegments (line 33): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 53): Dung de xay dung UI widget theo state hien tai.
- _buildGlassAppBar (line 207): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildClusterCard (line 266): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildMetricRow (line 342): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildChurnRow (line 364): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\admin\flash_sale_screen.dart
- createState (line 16): Tao moi va luu du lieu.
- build (line 20): Dung de xay dung UI widget theo state hien tai.
- _buildCountdownCard (line 78): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildTimeBox (line 124): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildProductCard (line 133): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\admin\loyalty_membership_screen.dart
- createState (line 16): Tao moi va luu du lieu.
- build (line 28): Dung de xay dung UI widget theo state hien tai.
- _buildGlassAppBar (line 73): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildTierCard (line 99): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\admin\marketing_dashboard_screen.dart
- createState (line 25): Tao moi va luu du lieu.
- initState (line 33): Khoi tao du lieu, listener hoac config ban dau.
- _loadStats (line 38): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 58): Dung de xay dung UI widget theo state hien tai.
- _buildHeader (line 174): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildStatsRow (line 259): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildStatCard (line 281): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\admin\push_campaign_screen.dart
- createState (line 16): Tao moi va luu du lieu.
- _sendPush (line 24): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 44): Dung de xay dung UI widget theo state hien tai.
- _buildGlassAppBar (line 109): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildPhonePreview (line 135): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildSettingsCard (line 202): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildTextField (line 241): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\admin\statistics_screen.dart
- createState (line 15): Tao moi va luu du lieu.
- initState (line 42): Khoi tao du lieu, listener hoac config ban dau.
- dispose (line 50): Giai phong tai nguyen, controller, stream/listener.
- _fetchOverview (line 55): Xu ly nghiep vu theo ngu canh cua file/module.
- _fetchChartData (line 79): Xu ly nghiep vu theo ngu canh cua file/module.
- _onMetricTap (line 121): Xu ly nghiep vu theo ngu canh cua file/module.
- _onPeriodChanged (line 135): Xu ly nghiep vu theo ngu canh cua file/module.
- _getOverviewValue (line 142): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 152): Dung de xay dung UI widget theo state hien tai.
- _buildStatCard (line 204): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildPeriodFilter (line 266): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildPeriodChip (line 282): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildDateSelector (line 308): Xu ly nghiep vu theo ngu canh cua file/module.
- _showPickerDialog (line 420): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildChartSection (line 457): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildBarChart (line 541): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildLineChart (line 620): Xu ly nghiep vu theo ngu canh cua file/module.
- _formatLabel (line 711): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildHeroHeader (line 726): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\admin\student_verification_screen.dart
- createState (line 18): Tao moi va luu du lieu.
- initState (line 32): Khoi tao du lieu, listener hoac config ban dau.
- dispose (line 39): Giai phong tai nguyen, controller, stream/listener.
- _loadVerifications (line 44): Xu ly nghiep vu theo ngu canh cua file/module.
- _review (line 64): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 86): Dung de xay dung UI widget theo state hien tai.
- _buildList (line 139): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildCard (line 168): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\admin\theme_management_screen.dart
- createState (line 20): Tao moi va luu du lieu.
- initState (line 53): Khoi tao du lieu, listener hoac config ban dau.
- _syncInitialTheme (line 60): Dong bo du lieu giua local va backend.
- _saveTheme (line 74): Xu ly logic chu de va style giao dien.
- _showSnack (line 97): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 108): Dung de xay dung UI widget theo state hien tai.
- _buildHeroHeader (line 178): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildThemeCard (line 258): Xu ly logic chu de va style giao dien.
- build (line 349): Dung de xay dung UI widget theo state hien tai.

## lib\screens\admin\users_management_screen.dart
- createState (line 18): Tao moi va luu du lieu.
- initState (line 29): Khoi tao du lieu, listener hoac config ban dau.
- _fetchUsers (line 34): Xu ly nghiep vu theo ngu canh cua file/module.
- _showSnack (line 63): Xu ly nghiep vu theo ngu canh cua file/module.
- _toggleUserStatus (line 87): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 136): Dung de xay dung UI widget theo state hien tai.
- _buildHeroHeader (line 168): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildFilters (line 271): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildUserTile (line 310): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\admin\voucher_management_screen.dart
- createState (line 21): Tao moi va luu du lieu.
- initState (line 29): Khoi tao du lieu, listener hoac config ban dau.
- _loadPromotions (line 34): Xu ly nghiep vu theo ngu canh cua file/module.
- _createPromotion (line 54): Xu ly nghiep vu theo ngu canh cua file/module.
- StatefulBuilder (line 66): Xu ly nghiep vu theo ngu canh cua file/module.
- _deletePromotion (line 176): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 201): Dung de xay dung UI widget theo state hien tai.
- _buildGlassAppBar (line 293): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildUsageChart (line 338): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildEmptyState (line 403): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildPromotionCard (line 425): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildField (line 561): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildDropdown (line 577): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\avatar_3d_screen.dart
- createState (line 12): Tao moi va luu du lieu.
- initState (line 21): Khoi tao du lieu, listener hoac config ban dau.
- _loadLatestAvatar (line 26): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 65): Dung de xay dung UI widget theo state hien tai.
- _buildBody (line 83): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\avaturn_screen.dart
- createState (line 24): Tao moi va luu du lieu.
- initState (line 32): Khoi tao du lieu, listener hoac config ban dau.
- _handleAvaturnMessage (line 60): Xu ly nghiep vu theo ngu canh cua file/module.
- _downloadAndCacheAvatar (line 73): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 117): Dung de xay dung UI widget theo state hien tai.

## lib\screens\chat\chat_list_screen.dart
- createState (line 12): Tao moi va luu du lieu.
- initState (line 17): Khoi tao du lieu, listener hoac config ban dau.
- build (line 25): Dung de xay dung UI widget theo state hien tai.

## lib\screens\chat\chat_room_screen.dart
- createState (line 21): Tao moi va luu du lieu.
- initState (line 31): Khoi tao du lieu, listener hoac config ban dau.
- dispose (line 56): Giai phong tai nguyen, controller, stream/listener.
- _sendMessage (line 63): Xu ly nghiep vu theo ngu canh cua file/module.
- _onTypingChanged (line 83): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 95): Dung de xay dung UI widget theo state hien tai.
- _buildMessageBubble (line 140): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildGiftBubbleContent (line 176): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildInputArea (line 193): Xu ly nghiep vu theo ngu canh cua file/module.
- _openGiftBuilder (line 227): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\gifts\gift_notification_screen.dart
- createState (line 15): Tao moi va luu du lieu.
- initState (line 26): Khoi tao du lieu, listener hoac config ban dau.
- _getToken (line 31): Xu ly nghiep vu theo ngu canh cua file/module.
- _loadGifts (line 36): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 62): Dung de xay dung UI widget theo state hien tai.
- _buildEmptyState (line 123): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildGiftCard (line 144): Xu ly nghiep vu theo ngu canh cua file/module.
- _formatDate (line 255): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\gifts\gift_open_screen.dart
- createState (line 24): Tao moi va luu du lieu.
- initState (line 79): Khoi tao du lieu, listener hoac config ban dau.
- dispose (line 121): Giai phong tai nguyen, controller, stream/listener.
- _requestCameraAndStart (line 128): Xu ly nghiep vu theo ngu canh cua file/module.
- _markAsOpened (line 138): Xu ly nghiep vu theo ngu canh cua file/module.
- _startUnboxingAnimation (line 151): Xu ly nghiep vu theo ngu canh cua file/module.
- _captureScreenshot (line 176): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 209): Dung de xay dung UI widget theo state hien tai.
- _buildBackground (line 256): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildThemeDecorations (line 266): Xu ly logic chu de va style giao dien.
- _decorCircle (line 284): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildGiftContent (line 291): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildUnboxingView (line 311): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildRevealedView (line 342): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildMessageCard (line 428): Xu ly nghiep vu theo ngu canh cua file/module.
- _getModelName (line 495): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\gifts\gift_preview_screen.dart
- createState (line 27): Tao moi va luu du lieu.
- dispose (line 47): Giai phong tai nguyen, controller, stream/listener.
- _getToken (line 52): Xu ly nghiep vu theo ngu canh cua file/module.
- _sendGift (line 57): Xu ly nghiep vu theo ngu canh cua file/module.
- _showSnackBar (line 99): Xu ly nghiep vu theo ngu canh cua file/module.
- _showSuccessDialog (line 106): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 166): Dung de xay dung UI widget theo state hien tai.

## lib\screens\gifts\gift_qr_screen.dart
- createState (line 10): Tao moi va luu du lieu.
- initState (line 17): Khoi tao du lieu, listener hoac config ban dau.
- build (line 25): Dung de xay dung UI widget theo state hien tai.
- _buildScanner (line 43): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildQRDisplay (line 83): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleScannedCode (line 131): Xu ly nghiep vu theo ngu canh cua file/module.
- _navigateToClaim (line 142): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\gifts\themed_gift_builder_screen.dart
- createState (line 12): Tao moi va luu du lieu.
- initState (line 28): Khoi tao du lieu, listener hoac config ban dau.
- dispose (line 42): Giai phong tai nguyen, controller, stream/listener.
- build (line 61): Dung de xay dung UI widget theo state hien tai.
- _buildSectionTitle (line 115): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildModelCarousel (line 139): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildStickerGrid (line 236): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildDesignArea (line 303): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildMessageInput (line 489): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildBottomBar (line 517): Xu ly nghiep vu theo ngu canh cua file/module.
- _getIconForModel (line 594): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\social\friend_management_screen.dart
- createState (line 13): Tao moi va luu du lieu.
- initState (line 21): Khoi tao du lieu, listener hoac config ban dau.
- _initNotificationListener (line 34): Xu ly nghiep vu theo ngu canh cua file/module.
- dispose (line 51): Giai phong tai nguyen, controller, stream/listener.
- build (line 66): Dung de xay dung UI widget theo state hien tai.
- _buildFriendListTab (line 97): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildSearchResults (line 130): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildActualFriends (line 161): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildReceivedRequestsTab (line 187): Xu ly nghiep vu theo ngu canh cua file/module.
- _buildSentRequestsTab (line 224): Xu ly nghiep vu theo ngu canh cua file/module.
- _openChat (line 252): Xu ly nghiep vu theo ngu canh cua file/module.
- _showFriendOptions (line 267): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleSendFriendRequest (line 291): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleAcceptRequest (line 382): Xu ly nghiep vu theo ngu canh cua file/module.
- _handleDeclineRequest (line 469): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\screens\store\combo_suggestion_screen.dart
- createState (line 11): Tao moi va luu du lieu.
- initState (line 19): Khoi tao du lieu, listener hoac config ban dau.
- build (line 27): Dung de xay dung UI widget theo state hien tai.
- _buildHeader (line 75): Xu ly nghiep vu theo ngu canh cua file/module.
- _runAnalysis (line 121): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 144): Dung de xay dung UI widget theo state hien tai.
- build (line 201): Dung de xay dung UI widget theo state hien tai.
- build (line 217): Dung de xay dung UI widget theo state hien tai.

## lib\screens\store\inventory_screen.dart
- createState (line 13): Tao moi va luu du lieu.
- initState (line 21): Khoi tao du lieu, listener hoac config ban dau.
- build (line 29): Dung de xay dung UI widget theo state hien tai.
- _showItemDialog (line 66): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 81): Dung de xay dung UI widget theo state hien tai.
- _confirmDelete (line 141): Xu ly nghiep vu theo ngu canh cua file/module.
- createState (line 167): Tao moi va luu du lieu.
- initState (line 182): Khoi tao du lieu, listener hoac config ban dau.
- _pickFile (line 191): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 217): Dung de xay dung UI widget theo state hien tai.
- _submit (line 311): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 358): Dung de xay dung UI widget theo state hien tai.

## lib\screens\store\revenue_screen.dart
- createState (line 12): Tao moi va luu du lieu.
- initState (line 20): Khoi tao du lieu, listener hoac config ban dau.
- build (line 28): Dung de xay dung UI widget theo state hien tai.
- _buildChart (line 81): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 163): Dung de xay dung UI widget theo state hien tai.

## lib\screens\store\store_dashboard_screen.dart
- createState (line 14): Tao moi va luu du lieu.
- initState (line 19): Khoi tao du lieu, listener hoac config ban dau.
- build (line 27): Dung de xay dung UI widget theo state hien tai.
- _buildStatGrid (line 118): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 178): Dung de xay dung UI widget theo state hien tai.
- build (line 236): Dung de xay dung UI widget theo state hien tai.

## lib\widgets\calendar_popup.dart
- createState (line 18): Tao moi va luu du lieu.
- show (line 20): Hien thi dialog, popup, bottom sheet hoac thong bao.
- initState (line 38): Khoi tao du lieu, listener hoac config ban dau.
- _fetchEvents (line 53): Xu ly nghiep vu theo ngu canh cua file/module.
- _getEventsForDay (line 80): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 87): Dung de xay dung UI widget theo state hien tai.
- _getEventsForDay (line 140): Xu ly nghiep vu theo ngu canh cua file/module.
- _showAddNoteDialog (line 306): Xu ly nghiep vu theo ngu canh cua file/module.
- _showThemeSwitcher (line 388): Xu ly logic chu de va style giao dien.

## lib\widgets\confetti_painter.dart
- paint (line 11): Xu ly nghiep vu theo ngu canh cua file/module.
- shouldRepaint (line 33): Xu ly nghiep vu theo ngu canh cua file/module.
- createState (line 47): Tao moi va luu du lieu.
- initState (line 56): Khoi tao du lieu, listener hoac config ban dau.
- didUpdateWidget (line 66): Xu ly nghiep vu theo ngu canh cua file/module.
- _generateParticles (line 74): Xu ly nghiep vu theo ngu canh cua file/module.
- dispose (line 98): Giai phong tai nguyen, controller, stream/listener.
- build (line 104): Dung de xay dung UI widget theo state hien tai.

## lib\widgets\custom_loading.dart
- build (line 9): Dung de xay dung UI widget theo state hien tai.

## lib\widgets\glb_model_viewer.dart
- createState (line 28): Tao moi va luu du lieu.
- initState (line 36): Khoi tao du lieu, listener hoac config ban dau.
- didUpdateWidget (line 42): Xu ly nghiep vu theo ngu canh cua file/module.
- _resolveSource (line 49): Xu ly nghiep vu theo ngu canh cua file/module.
- build (line 80): Dung de xay dung UI widget theo state hien tai.

## lib\widgets\particle_overlay.dart
- createState (line 15): Tao moi va luu du lieu.
- initState (line 24): Khoi tao du lieu, listener hoac config ban dau.
- didUpdateWidget (line 34): Xu ly nghiep vu theo ngu canh cua file/module.
- _generateParticles (line 44): Xu ly nghiep vu theo ngu canh cua file/module.
- dispose (line 56): Giai phong tai nguyen, controller, stream/listener.
- build (line 62): Dung de xay dung UI widget theo state hien tai.
- paint (line 92): Xu ly nghiep vu theo ngu canh cua file/module.
- _drawFireworkSpark (line 107): Xu ly nghiep vu theo ngu canh cua file/module.
- _drawHeart (line 135): Xu ly nghiep vu theo ngu canh cua file/module.
- shouldRepaint (line 161): Xu ly nghiep vu theo ngu canh cua file/module.

## lib\widgets\theme_particles.dart
- createState (line 10): Tao moi va luu du lieu.
- initState (line 19): Khoi tao du lieu, listener hoac config ban dau.
- didChangeDependencies (line 39): Xu ly nghiep vu theo ngu canh cua file/module.
- dispose (line 58): Giai phong tai nguyen, controller, stream/listener.
- build (line 64): Dung de xay dung UI widget theo state hien tai.


