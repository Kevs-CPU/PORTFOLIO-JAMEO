import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    final appState = context.read<AppState>();

    _nameController = TextEditingController(
      text: appState.userName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Profile',
                style: theme.textTheme.titleMedium,
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  context.read<AppState>().updateUserName(value);
                },
              ),

              const SizedBox(height: 32),

              Text(
                'Appearance',
                style: theme.textTheme.titleMedium,
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dark theme',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),

                  Switch(
                    value: appState.isDarkMode,
                    onChanged: (value) {
                      context.read<AppState>().toggleTheme(value);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}