import 'package:flutter/material.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';

class ExperiencesScreen extends StatefulWidget {
  const ExperiencesScreen({super.key});

  @override
  State<ExperiencesScreen> createState() => _ExperiencesScreenState();
}

class _ExperiencesScreenState extends State<ExperiencesScreen> {
  final _urlController = TextEditingController();
  final _targetingKeyController = TextEditingController();
  final _targetingValueController = TextEditingController();
  final _experimentGroupController = TextEditingController();
  final _experimentVariantController = TextEditingController();

  ExperienceType? _filterType;
  ExperienceFamily? _filterFamily;
  bool _resolve = false;
  bool _loading = false;
  List<Experience> _experiences = const [];
  String? _statusMessage;

  @override
  void dispose() {
    _urlController.dispose();
    _targetingKeyController.dispose();
    _targetingValueController.dispose();
    _experimentGroupController.dispose();
    _experimentVariantController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    try {
      final exps = await Experiences.fetchExperiences(
        filterByType: _filterType,
        filterByFamily: _filterFamily,
        resolve: _resolve,
        url: _urlController.text.isEmpty ? null : _urlController.text,
      );
      setState(() {
        _experiences = exps;
        _statusMessage = 'Fetched ${exps.length} experiences';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Experiences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Targeting'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetingKeyController,
                  decoration: const InputDecoration(hintText: 'Key'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _targetingValueController,
                  decoration: const InputDecoration(hintText: 'Value'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Experiences.addTargeting(
                _targetingKeyController.text,
                _targetingValueController.text,
              );
              setState(() => _statusMessage =
                  'Added targeting ${_targetingKeyController.text}');
            },
            child: const Text('Add Targeting'),
          ),
          const Divider(height: 32),
          _section('Fetch'),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
                hintText: 'Optional URL override (uses current page if empty)'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ExperienceType?>(
            initialValue: _filterType,
            decoration: const InputDecoration(labelText: 'Filter by Type'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...ExperienceType.values.map(
                (t) => DropdownMenuItem(value: t, child: Text(t.value)),
              ),
            ],
            onChanged: (v) => setState(() => _filterType = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ExperienceFamily?>(
            initialValue: _filterFamily,
            decoration: const InputDecoration(labelText: 'Filter by Family'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...ExperienceFamily.values.map(
                (f) => DropdownMenuItem(value: f, child: Text(f.value)),
              ),
            ],
            onChanged: (v) => setState(() => _filterFamily = v),
          ),
          SwitchListTile(
            title: const Text('Resolve content'),
            value: _resolve,
            onChanged: (v) => setState(() => _resolve = v),
          ),
          ElevatedButton(
            onPressed: _loading ? null : _fetch,
            child: Text(_loading ? 'Fetching…' : 'Fetch Experiences'),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_statusMessage!),
            ),
          ],
          const Divider(height: 32),
          _section('Results'),
          if (_experiences.isEmpty)
            const Text('No experiences fetched yet.')
          else
            ..._experiences.map(_experienceCard),
          const Divider(height: 32),
          _section('QA'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  Experiences.clearFrequencyCaps();
                  setState(() => _statusMessage = 'Cleared frequency caps');
                },
                child: const Text('Clear Freq Caps'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final config = await Experiences.getFrequencyCapConfig();
                  setState(() => _statusMessage = 'Freq cap config: $config');
                },
                child: const Text('Show Freq Cap Config'),
              ),
              ElevatedButton(
                onPressed: () {
                  Experiences.clearReadEditorials();
                  setState(() => _statusMessage = 'Cleared read editorials');
                },
                child: const Text('Clear Editorials'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final ids = await Experiences.getReadEditorials();
                  setState(() => _statusMessage = 'Read editorials: $ids');
                },
                child: const Text('Show Editorials'),
              ),
              ElevatedButton(
                onPressed: () {
                  Experiences.clearExperimentAssignments();
                  setState(() => _statusMessage = 'Cleared experiments');
                },
                child: const Text('Clear Experiments'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final assignments =
                      await Experiences.getExperimentAssignments();
                  setState(() => _statusMessage = 'Experiments: $assignments');
                },
                child: const Text('Show Experiments'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _experimentGroupController,
                  decoration: const InputDecoration(hintText: 'Group ID'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _experimentVariantController,
                  decoration: const InputDecoration(hintText: 'Variant ID'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Experiences.setExperimentAssignment(
                groupId: _experimentGroupController.text,
                variantId: _experimentVariantController.text,
              );
              setState(() => _statusMessage = 'Set experiment assignment');
            },
            child: const Text('Set Experiment Assignment'),
          ),
        ],
      ),
    );
  }

  Widget _experienceCard(Experience exp) {
    final demoLink = RecirculationLink(
      url: exp.contentUrl ?? 'https://example.com',
      position: 0,
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exp.name,
                style: Theme.of(context).textTheme.titleMedium),
            Text('id: ${exp.id}'),
            Text('type: ${exp.type.value}'),
            if (exp.family != null) Text('family: ${exp.family!.value}'),
            if (exp.contentUrl != null) Text('url: ${exp.contentUrl}'),
            if (exp.resolvedContent != null)
              Text(
                'content: ${exp.resolvedContent!.length > 80 ? '${exp.resolvedContent!.substring(0, 80)}…' : exp.resolvedContent}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => Experiences.trackEligible(
                    experience: exp,
                    links: [demoLink],
                  ),
                  child: const Text('Eligible'),
                ),
                OutlinedButton(
                  onPressed: () => Experiences.trackImpression(
                    experience: exp,
                    links: [demoLink],
                  ),
                  child: const Text('Impression'),
                ),
                OutlinedButton(
                  onPressed: () => Experiences.trackClick(
                    experience: exp,
                    link: demoLink,
                  ),
                  child: const Text('Click'),
                ),
                OutlinedButton(
                  onPressed: () => Experiences.trackClose(exp),
                  child: const Text('Close'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final content =
                        await Experiences.resolveExperience(exp);
                    setState(() => _statusMessage = content == null
                        ? 'No content for ${exp.id}'
                        : 'Resolved ${exp.id}: ${content.length} chars');
                  },
                  child: const Text('Resolve'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final counts =
                        await Experiences.getFrequencyCapCounts(exp.id);
                    setState(() =>
                        _statusMessage = 'Counts ${exp.id}: $counts');
                  },
                  child: const Text('Counts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );
}
