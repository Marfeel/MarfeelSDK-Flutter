import 'package:flutter/material.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userIdController = TextEditingController();
  final _sessionVarNameController = TextEditingController();
  final _sessionVarValueController = TextEditingController();
  final _userVarNameController = TextEditingController();
  final _userVarValueController = TextEditingController();
  final _segmentController = TextEditingController();
  final _cdpSegmentController = TextEditingController();
  final _meterController = TextEditingController();
  String _resultText = '';
  bool _consent = true;

  @override
  void dispose() {
    _userIdController.dispose();
    _sessionVarNameController.dispose();
    _sessionVarValueController.dispose();
    _userVarNameController.dispose();
    _userVarValueController.dispose();
    _segmentController.dispose();
    _cdpSegmentController.dispose();
    _meterController.dispose();
    super.dispose();
  }

  void _showResult(String text) {
    setState(() => _resultText = text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('User ID'),
          TextField(
              controller: _userIdController,
              decoration: const InputDecoration(hintText: 'Site User ID')),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                CompassTracking.setSiteUserId(_userIdController.text),
            child: const Text('Set Site User ID'),
          ),
          const Divider(height: 32),
          _sectionTitle('User Type'),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                  onPressed: () =>
                      CompassTracking.setUserType(UserType.anonymous),
                  child: const Text('Anonymous')),
              ElevatedButton(
                  onPressed: () =>
                      CompassTracking.setUserType(UserType.logged),
                  child: const Text('Logged')),
              ElevatedButton(
                  onPressed: () =>
                      CompassTracking.setUserType(UserType.paid),
                  child: const Text('Paid')),
              ElevatedButton(
                  onPressed: () =>
                      CompassTracking.setUserType(UserType.custom(42)),
                  child: const Text('Custom(42)')),
            ],
          ),
          const Divider(height: 32),
          _sectionTitle('Getters'),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final id = await CompassTracking.getUserId();
                  _showResult('User ID: $id');
                },
                child: const Text('Get User ID'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final rfv = await CompassTracking.getRFV();
                  _showResult(rfv != null
                      ? 'RFV: ${rfv.rfv}, R: ${rfv.r}, F: ${rfv.f}, V: ${rfv.v}'
                      : 'RFV: null');
                },
                child: const Text('Get RFV'),
              ),
            ],
          ),
          if (_resultText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_resultText),
            ),
          ],
          const Divider(height: 32),
          _sectionTitle('Session Var'),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _sessionVarNameController,
                      decoration:
                          const InputDecoration(hintText: 'Name'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _sessionVarValueController,
                      decoration:
                          const InputDecoration(hintText: 'Value'))),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => CompassTracking.setSessionVar(
                _sessionVarNameController.text,
                _sessionVarValueController.text),
            child: const Text('Set Session Var'),
          ),
          const Divider(height: 32),
          _sectionTitle('User Var'),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _userVarNameController,
                      decoration:
                          const InputDecoration(hintText: 'Name'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _userVarValueController,
                      decoration:
                          const InputDecoration(hintText: 'Value'))),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => CompassTracking.setUserVar(
                _userVarNameController.text, _userVarValueController.text),
            child: const Text('Set User Var'),
          ),
          const Divider(height: 32),
          _sectionTitle('User Segments'),
          TextField(
              controller: _segmentController,
              decoration:
                  const InputDecoration(hintText: 'Segment name')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () =>
                    CompassTracking.addUserSegment(_segmentController.text),
                child: const Text('Add'),
              ),
              ElevatedButton(
                onPressed: () => CompassTracking.removeUserSegment(
                    _segmentController.text),
                child: const Text('Remove'),
              ),
              ElevatedButton(
                onPressed: () => CompassTracking.clearUserSegments(),
                child: const Text('Clear All'),
              ),
              ElevatedButton(
                onPressed: () => CompassTracking.setUserSegments(
                    ['tech', 'media', 'finance']),
                child: const Text('Set Batch'),
              ),
            ],
          ),
          const Divider(height: 32),
          _sectionTitle('CDP — Identity & Data'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => Cdp.cdpDoIdentityLink(
                    'registered_user_id', _userIdController.text,
                    isDeterministic: true),
                child: const Text('Link Identity'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final id = await Cdp.getCdpMasterId();
                  _showResult('CDP master_id: ${id ?? 'null'}');
                },
                child: const Text('Get master_id'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final data = await Cdp.getCdpData();
                  _showResult('CDP data: masterId=${data.masterId}, '
                      'rfv=${data.rfv?.rfv}, cohorts=${data.cohorts}');
                },
                child: const Text('Get CDP Data'),
              ),
            ],
          ),
          const Divider(height: 32),
          _sectionTitle('CDP — Segments'),
          TextField(
              controller: _cdpSegmentController,
              decoration: const InputDecoration(hintText: 'CDP segment name')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () =>
                    Cdp.addCdpSegment(_cdpSegmentController.text),
                child: const Text('Add'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Cdp.removeCdpSegment(_cdpSegmentController.text),
                child: const Text('Remove'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Cdp.setCdpSegments(['sports_fan', 'subscriber']),
                child: const Text('Set Batch'),
              ),
              ElevatedButton(
                onPressed: () => Cdp.clearCdpSegments(),
                child: const Text('Clear All'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final segments = await Cdp.getCdpSegments();
                  _showResult('CDP segments: $segments');
                },
                child: const Text('Get'),
              ),
            ],
          ),
          const Divider(height: 32),
          _sectionTitle('CDP — Meters'),
          TextField(
              controller: _meterController,
              decoration: const InputDecoration(hintText: 'Meter name')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final meters = await Cdp.getMeterSnapshot();
                  _showResult('Meters: '
                      '${meters.map((m) => '${m.name}=${m.count}/${m.threshold}').join(', ')}');
                },
                child: const Text('Snapshot'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final m = await Cdp.getMeter(_meterController.text);
                  _showResult(m != null
                      ? '${m.name}: ${m.count}/${m.threshold} '
                          '(reached=${m.reached})'
                      : 'Meter not found in mirror');
                },
                child: const Text('Get'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final m = await Cdp.incrementMeter(_meterController.text);
                    _showResult(m != null
                        ? 'Incremented ${m.name} -> ${m.count}'
                        : 'Increment no-op (not ready)');
                  } on MeterNotFoundError catch (e) {
                    _showResult('Meter "${e.meterName}" not configured');
                  }
                },
                child: const Text('Increment'),
              ),
            ],
          ),
          const Divider(height: 32),
          _sectionTitle('Consent'),
          SwitchListTile(
            title: const Text('User Consent'),
            value: _consent,
            onChanged: (v) {
              setState(() => _consent = v);
              CompassTracking.setConsent(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
