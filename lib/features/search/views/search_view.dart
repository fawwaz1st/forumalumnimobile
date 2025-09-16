import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/utils/debouncer.dart';

import '../providers/search_provider.dart';
import '../../posts/providers/post_feed_provider.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final _q = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 400);
  DateTime? _from;
  DateTime? _to;
  String? _author;
  final Set<String> _categories = {};
  String _sort = 'relevance';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom ? (_from ?? now) : (_to ?? now);
    final res = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDate: initial,
    );
    if (res != null) setState(() => isFrom ? _from = res : _to = res);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final notifier = ref.read(searchControllerProvider.notifier);
    final catsAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian Lanjutan'),
        actions: [
          IconButton(onPressed: () => ref.read(searchControllerProvider.notifier).clearHistory(), icon: const Icon(Icons.delete_sweep_outlined)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _q,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Kata kunci...', border: OutlineInputBorder()),
                        onSubmitted: (_) => _doSearch(notifier),
                        onChanged: (_) => _debouncer(() => _doSearch(notifier)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(onPressed: () => _doSearch(notifier), icon: const Icon(Icons.search), label: const Text('Cari')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _dateChip(context, label: 'Dari', date: _from, onTap: () => _pickDate(context, true))),
                    const SizedBox(width: 8),
                    Expanded(child: _dateChip(context, label: 'Sampai', date: _to, onTap: () => _pickDate(context, false))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.person_search_outlined), hintText: 'Penulis (nama atau email)', border: OutlineInputBorder()),
                  onChanged: (v) => _author = v,
                ),
                const SizedBox(height: 8),
                catsAsync.maybeWhen(
                  data: (cats) => Wrap(
                    spacing: 6,
                    children: [
                      for (final c in cats)
                        ChoiceChip(
                          selected: _categories.contains(c.id),
                          onSelected: (s) => setState(() => s ? _categories.add(c.id) : _categories.remove(c.id)),
                          label: Text(c.name),
                        ),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'relevance', label: Text('Relevansi'), icon: Icon(Icons.sort)),
                    ButtonSegment(value: 'date', label: Text('Tanggal'), icon: Icon(Icons.calendar_today_outlined)),
                    ButtonSegment(value: 'votes', label: Text('Vote'), icon: Icon(Icons.trending_up)),
                  ],
                  selected: {_sort},
                  onSelectionChanged: (v) => setState(() => _sort = v.first),
                ),
              ],
            ),
          ),
          if (state.history.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  const SizedBox(width: 12),
                  for (final h in state.history)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(label: Text(h), onPressed: () {
                        _q.text = h;
                        _doSearch(notifier);
                      }),
                    ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : (state.results.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        itemCount: state.results.length,
                        itemBuilder: (context, index) {
                          final p = state.results[index];
                          return ListTile(
                            title: Text(p.title),
                            subtitle: Text('${p.author.name} • ${p.votes} votes'),
                            onTap: () => context.go('/posts/${p.id}'),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(BuildContext context, {required String label, DateTime? date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(Icons.date_range_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(date == null ? label : '${date.day}/${date.month}/${date.year}'),
          ],
        ),
      ),
    );
  }

  void _doSearch(AdvancedSearchController notifier) {
    final f = SearchFilters(query: _q.text.trim(), from: _from, to: _to, author: _author, categories: _categories.toList(), sort: _sort);
    notifier.setFilters(f);
    notifier.search();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.search_off, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Tidak ada hasil'),
        ],
      ),
    );
  }
}
