import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../providers/local_chat_provider.dart';
import '../../../../state/app_state.dart';

class LocalMeshChatPage extends StatefulWidget {
  const LocalMeshChatPage({super.key});

  @override
  State<LocalMeshChatPage> createState() => _LocalMeshChatPageState();
}

class _LocalMeshChatPageState extends State<LocalMeshChatPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController =
      TextEditingController();

  bool _locationServiceEnabled = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkLocationService();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationService();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _messageController.dispose();

    super.dispose();
  }

  // ============================================================
  // Location Service
  // ============================================================

  Future<void> _checkLocationService() async {
    final serviceStatus =
        await Permission.location.serviceStatus;

    if (!mounted) return;

    setState(() {
      _locationServiceEnabled = serviceStatus.isEnabled;
    });
  }

  // ============================================================
  // Actions
  // ============================================================

  Future<void> _startChat() async {
  final provider = context.read<LocalChatProvider>();

  await _checkLocationService();

  if (!mounted) return;

  if (!_locationServiceEnabled) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            14,
            0,
            14,
            14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(
                Icons.location_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Turn on Location to discover nearby devices.',
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

    return;
  }

  await provider.startLocalChat();
}
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) return;

    await context
        .read<LocalChatProvider>()
        .sendMessage(message);

    if (mounted) {
      _messageController.clear();
    }
  }

  Future<void> _stopChat() async {
    await context
        .read<LocalChatProvider>()
        .stopLocalChat();
  }

  // ============================================================
  // Main Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final bool isDarkMode = appState.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<LocalChatProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _buildHeader(
                  context,
                  theme,
                ),

                _buildStatusCard(
                  context,
                  theme,
                  provider,
                  isDarkMode,
                ),

                if (!_locationServiceEnabled)
                  _buildLocationMessage(
                    theme,
                    isDarkMode,
                  ),

                _buildNearbyDevicesCard(
                  context,
                  theme,
                  provider,
                  isDarkMode,
                ),

                Expanded(
                  child: _buildMessages(
                    context,
                    theme,
                    provider,
                    isDarkMode,
                  ),
                ),

                _buildBottomArea(
                  context,
                  theme,
                  provider,
                  isDarkMode,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // Header
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
  ) {
    final Color primaryText =
        theme.colorScheme.onSurface;

    final Color secondaryText =
        theme.colorScheme.onSurface.withValues(
      alpha: 0.55,
    );

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back_rounded,
                color: primaryText,
                size: 27,
              ),
              tooltip: 'Back',
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local Mesh Chat',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Offline peer-to-peer communication',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Status Card
  // ============================================================

  Widget _buildStatusCard(
    BuildContext context,
    ThemeData theme,
    LocalChatProvider provider,
    bool isDarkMode,
  ) {
    final bool connected = provider.isConnected;
    final bool discovering = provider.isDiscovering;

    final Color statusColor = connected
        ? const Color(0xFF16A34A)
        : discovering
            ? const Color(0xFFF59E0B)
            : const Color(0xFF64748B);

    final String statusText = connected
        ? 'Connected'
        : discovering
            ? 'Discovering nearby devices'
            : 'Not connected';

    final String subtitle = connected
        ? provider.connectedDeviceName ??
            'Nearby device connected'
        : 'Offline peer-to-peer communication';

    final Color cardColor = isDarkMode
        ? const Color(0xFF101D2D)
        : Colors.white;

    final Color primaryText =
        theme.colorScheme.onSurface;

    final Color secondaryText =
        theme.colorScheme.onSurface.withValues(
      alpha: 0.55,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        14,
        4,
        14,
        8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: statusColor.withValues(
            alpha: isDarkMode ? 0.22 : 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              connected
                  ? Icons.link_rounded
                  : Icons.wifi_tethering_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusDot(
            color: statusColor,
            label: connected
                ? 'Online'
                : discovering
                    ? 'Searching'
                    : 'Offline',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot({
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Location Message
  // ============================================================

  Widget _buildLocationMessage(
    ThemeData theme,
    bool isDarkMode,
  ) {
    const Color infoColor = Color(0xFFF59E0B);

    final Color cardColor = isDarkMode
        ? const Color(0xFF211B10)
        : const Color(0xFFFFFBEB);

    final Color primaryText =
        theme.colorScheme.onSurface;

    final Color secondaryText =
        theme.colorScheme.onSurface.withValues(
      alpha: 0.58,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        14,
        0,
        14,
        8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: infoColor.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: infoColor.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: infoColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Location is off',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Turn on Location to discover nearby devices.',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Nearby Devices
  // ============================================================

  Widget _buildNearbyDevicesCard(
    BuildContext context,
    ThemeData theme,
    LocalChatProvider provider,
    bool isDarkMode,
  ) {
    final bool discovering = provider.isDiscovering;

    final Color cardColor = isDarkMode
        ? const Color(0xFF101D2D)
        : Colors.white;

    final Color deviceColor = isDarkMode
        ? const Color(0xFF142438)
        : const Color(0xFFF1F5F9);

    final Color primaryText =
        theme.colorScheme.onSurface;

    final Color secondaryText =
        theme.colorScheme.onSurface.withValues(
      alpha: 0.48,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        14,
        0,
        14,
        8,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: theme.dividerColor.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.devices_rounded,
                  color: Color(0xFF0891B2),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nearby Devices',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (discovering)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0891B2),
                    ),
                  )
                else
                  Text(
                    '${provider.nearbyDevices.length}',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (provider.nearbyDevices.isNotEmpty)
            ...provider.nearbyDevices.map(
              (deviceName) {
                final bool isConnected =
                    provider.connectedDeviceName ==
                        deviceName;

                return Container(
                  margin: const EdgeInsets.fromLTRB(
                    8,
                    0,
                    8,
                    7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: deviceColor,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0891B2)
                                  .withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isConnected
                              ? Icons.link_rounded
                              : Icons.smartphone_rounded,
                          color: isConnected
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF0891B2),
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          deviceName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isConnected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF16A34A),
                          size: 18,
                        ),
                    ],
                  ),
                );
              },
            ),
          if (provider.nearbyDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                13,
                0,
                13,
                11,
              ),
              child: Row(
                children: [
                  Icon(
                    discovering
                        ? Icons.radar_rounded
                        : Icons.devices_other_outlined,
                    color: secondaryText,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      discovering
                          ? 'Searching for nearby devices...'
                          : 'No devices discovered',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Messages
  // ============================================================

  Widget _buildMessages(
    BuildContext context,
    ThemeData theme,
    LocalChatProvider provider,
    bool isDarkMode,
  ) {
    if (provider.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.forum_outlined,
                size: 42,
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.16),
              ),
              const SizedBox(height: 9),
              Text(
                'No messages yet',
                style: TextStyle(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.65),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                provider.isConnected
                    ? 'Send a message to the connected device.'
                    : 'Connect to a nearby device to start chatting.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.36),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        14,
        8,
        14,
        10,
      ),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];

        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 290,
            ),
            margin: const EdgeInsets.only(
              bottom: 7,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 9,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF19BFD5),
                  Color(0xFF2864D7),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // Bottom Area
  // ============================================================

  Widget _buildBottomArea(
    BuildContext context,
    ThemeData theme,
    LocalChatProvider provider,
    bool isDarkMode,
  ) {
    final bool connected = provider.isConnected;
    final bool active =
        provider.isDiscovering || connected;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        7,
        12,
        10,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(
              alpha: 0.30,
            ),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (active)
              _buildMessageInput(
                context,
                theme,
                provider,
                isDarkMode,
              ),
            if (active)
              const SizedBox(height: 7),
            if (active)
              SizedBox(
                width: double.infinity,
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: _stopChat,
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                    size: 16,
                  ),
                  label: const Text(
                    'Stop Nearby Chat',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF0891B2),
                    side: BorderSide(
                      color: const Color(0xFF0891B2)
                          .withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: provider.isStarting
                      ? null
                      : _startChat,
                  icon: provider.isStarting
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.wifi_tethering_rounded,
                          size: 20,
                        ),
                  label: Text(
                    provider.isStarting
                        ? 'Starting...'
                        : 'Start Nearby Chat',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF0891B2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Message Input
  // ============================================================

  Widget _buildMessageInput(
    BuildContext context,
    ThemeData theme,
    LocalChatProvider provider,
    bool isDarkMode,
  ) {
    final bool canSend = provider.isConnected;

    final Color inputColor = isDarkMode
        ? const Color(0xFF142438)
        : const Color(0xFFF1F5F9);

    final Color borderColor = isDarkMode
        ? const Color(0xFF304760)
        : const Color(0xFFD5DEE8);

    final Color primaryText =
        theme.colorScheme.onSurface;

    final Color hintColor =
        theme.colorScheme.onSurface.withValues(
      alpha: 0.42,
    );

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: inputColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.06,
                    ),
                    blurRadius: 8,
                  ),
              ],
            ),
            child: TextField(
              controller: _messageController,
              enabled: canSend,
              textInputAction:
                  TextInputAction.send,
              onSubmitted: canSend
                  ? (_) => _sendMessage()
                  : null,
              style: TextStyle(
                color: primaryText,
                fontSize: 12.5,
              ),
              decoration: InputDecoration(
                hintText: canSend
                    ? 'Type a message...'
                    : 'Waiting for connection...',
                hintStyle: TextStyle(
                  color: hintColor,
                  fontSize: 11.5,
                ),
                prefixIcon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: isDarkMode
                      ? const Color(0xFF8DA2B8)
                      : const Color(0xFF64748B),
                  size: 17,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 11,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Material(
          color: canSend
              ? const Color(0xFF0891B2)
              : isDarkMode
                  ? const Color(0xFF263647)
                  : const Color(0xFFE2E8F0),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: canSend ? _sendMessage : null,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.send_rounded,
                color: canSend
                    ? Colors.white
                    : isDarkMode
                        ? const Color(0xFF65778A)
                        : const Color(0xFF94A3B8),
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }
}