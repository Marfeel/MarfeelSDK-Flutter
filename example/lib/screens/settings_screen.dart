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
  final _consentIdController = TextEditingController(text: 'privacy_policy');
  final _consentVersionController = TextEditingController(text: '1');
  final _emailController = TextEditingController();
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
    _consentIdController.dispose();
    _consentVersionController.dispose();
    _emailController.dispose();
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
                  final sessionId = await CompassTracking.getSessionId();
                  _showResult('Session ID: $sessionId');
                },
                child: const Text('Get Session ID'),
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
          _sectionTitle('CDP — Identity & Profile'),
          TextField(
              controller: _emailController,
              decoration: const InputDecoration(hintText: 'Email to hash')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await Cdp.setIdentity(
                      CdpIdentityTypes.registeredUserId, _userIdController.text,
                      isDeterministic: true);
                  _showResult('Identity set; master_id: '
                      '${await Cdp.getMasterId() ?? 'null'}');
                },
                child: const Text('Set Identity'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final digest = await Cdp.hashEmail(_emailController.text);
                  await Cdp.setIdentity(CdpIdentityTypes.emailSha256, digest);
                  _showResult('Linked email_sha256 $digest');
                },
                child: const Text('Set Hashed Email'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await Cdp.deleteIdentity(CdpIdentityTypes.registeredUserId);
                  _showResult('Deleted registered_user_id identities');
                },
                child: const Text('Delete Identity'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final id = await Cdp.getMasterId();
                  _showResult('CDP master_id: ${id ?? 'null'}');
                },
                child: const Text('Get master_id'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final data = await Cdp.getUserProfile();
                  _showResult('CDP profile: masterId=${data.masterId}, '
                      'rfv=${data.rfv?.rfv}, cohorts=${data.cohorts}, '
                      'fresh=${data.identityFresh}');
                },
                child: const Text('Get Profile'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await CompassTracking.resetUser();
                  final id = await CompassTracking.getUserId();
                  _showResult('User reset; new user id: $id');
                },
                child: const Text('Reset User'),
              ),
            ],
          ),
          const Divider(height: 32),
          _sectionTitle('CDP — Server Segments & Properties'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final segments = await Cdp.getServerSegments();
                  _showResult('Server segments: $segments');
                },
                child: const Text('Server Segments'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final properties = await Cdp.getServerProperties();
                  _showResult('Server properties: $properties');
                },
                child: const Text('Server Properties'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final segments = await CompassTracking.getUserSegments();
                  _showResult('Beacon useg: $segments');
                },
                child: const Text('Merged Segments'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final vars = await CompassTracking.getUserVars();
                  _showResult('Beacon uvar: $vars');
                },
                child: const Text('Merged Vars'),
              ),
            ],
          ),
          const Divider(height: 32),
          _sectionTitle('CDP — Publisher Consents'),
          TextField(
              controller: _consentIdController,
              decoration: const InputDecoration(hintText: 'Consent id')),
          const SizedBox(height: 8),
          TextField(
              controller: _consentVersionController,
              decoration: const InputDecoration(hintText: 'Version id')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _trackConsent(CdpConsentStatus.accepted),
                child: const Text('Accept'),
              ),
              ElevatedButton(
                onPressed: () => _trackConsent(CdpConsentStatus.rejected),
                child: const Text('Reject'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final definition = await Cdp.getConsent(CdpConsentRef(
                      consentId: _consentIdController.text,
                      versionId: _versionOrNull()));
                  _showResult(definition == null
                      ? 'Consent not found'
                      : '${definition.name} (${definition.acceptMethod}, '
                          '${definition.showPolicy.wireValue}) '
                          'v${definition.version?.versionId}: '
                          '${definition.version?.displayPrompt}');
                },
                child: const Text('Definition'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final granted = await Cdp.hasConsent(CdpConsentQuery(
                      consentId: _consentIdController.text,
                      versionId: _versionOrNull(),
                      email: _emailOrNull()));
                  _showResult('Has consent: $granted');
                },
                child: const Text('Has Consent?'),
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

  String? _versionOrNull() {
    final version = _consentVersionController.text.trim();
    return version.isEmpty ? null : version;
  }

  String? _emailOrNull() {
    final email = _emailController.text.trim();
    return email.isEmpty ? null : email;
  }

  Future<void> _trackConsent(CdpConsentStatus status) async {
    final record = await Cdp.trackConsent(CdpConsent(
      consentId: _consentIdController.text,
      versionId: _consentVersionController.text,
      status: status,
      metadata: const {'source': 'example_app'},
      email: _emailOrNull(),
    ));
    _showResult(record == null
        ? 'Consent not recorded (CDP disabled or offline)'
        : 'Consent ${record.status}: recorded=${record.recorded}, '
            'stored=${record.stored}, master=${record.masterId}');
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
