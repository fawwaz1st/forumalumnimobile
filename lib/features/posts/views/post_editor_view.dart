import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../providers/post_feed_provider.dart';
import '../data/posts_repository.dart';
import '../models/post.dart';
import 'package:go_router/go_router.dart';

class PostEditorView extends ConsumerStatefulWidget {
  const PostEditorView({super.key, this.id});
  final String? id;

  @override
  ConsumerState<PostEditorView> createState() => _PostEditorViewState();
}

class _PostEditorViewState extends ConsumerState<PostEditorView> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _preview = false;
  String _categoryId = 'info';
  final Set<String> _tagIds = {};
  bool _saving = false;

  String get _draftKey => widget.id == null ? 'draft_post_new' : 'draft_post_edit_${widget.id}';

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final repo = ref.read(postsRepositoryProvider);
    // Try load draft first
    final draft = await repo.readDraft(_draftKey);
    if (draft != null) {
      setState(() {
        _titleCtrl.text = (draft['title'] as String?) ?? '';
        _contentCtrl.text = (draft['content'] as String?) ?? '';
        _categoryId = (draft['categoryId'] as String?) ?? 'info';
        _tagIds
          ..clear()
          ..addAll(((draft['tagIds'] as List?)?.cast<String>()) ?? const []);
      });
    } else if (widget.id != null) {
      // Load post for edit
      final p = await ref.read(postsRepositoryProvider).getPost(widget.id!);
      setState(() {
        _titleCtrl.text = p.title;
        _contentCtrl.text = p.contentMarkdown;
        _categoryId = p.category?.id ?? 'info';
        _tagIds
          ..clear()
          ..addAll(p.tags.map((e) => e.id));
      });
    }
  }

  Future<void> _saveDraft() async {
    final repo = ref.read(postsRepositoryProvider);
    await repo.saveDraft(_draftKey, {
      'title': _titleCtrl.text,
      'content': _contentCtrl.text,
      'categoryId': _categoryId,
      'tagIds': _tagIds.toList(),
    });
  }

  Future<void> _deleteDraft() async {
    await ref.read(postsRepositoryProvider).deleteDraft(_draftKey);
  }

  Future<void> _pickAndInsertImage() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 70, // Reduced quality for smaller size
        minWidth: 1000, // Reduced size for faster upload
        minHeight: 600,
      );
      final url = await ref.read(postsRepositoryProvider).uploadImageBytes(Uint8List.fromList(compressed), fileName: xfile.name);
      final insert = "\n\n![]($url)\n\n";
      final selection = _contentCtrl.selection;
      final text = _contentCtrl.text;
      final newText = text.replaceRange(selection.start == -1 ? text.length : selection.start, selection.end == -1 ? text.length : selection.end, insert);
      setState(() {
        _contentCtrl.text = newText;
        _contentCtrl.selection = TextSelection.collapsed(offset: newText.length);
      });
      await _saveDraft();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambahkan gambar: $e')));
    }
  }

  Future<void> _publish() async {
    setState(() => _saving = true);
    try {
      Post p;
      if (widget.id == null) {
        p = await ref.read(postsRepositoryProvider).createPost(
              title: _titleCtrl.text.trim(),
              contentMarkdown: _contentCtrl.text,
              categoryId: _categoryId,
              tagIds: _tagIds.toList(),
            );
      } else {
        p = await ref.read(postsRepositoryProvider).updatePost(
              id: widget.id!,
              title: _titleCtrl.text.trim(),
              contentMarkdown: _contentCtrl.text,
              categoryId: _categoryId,
              tagIds: _tagIds.toList(),
            );
      }
      // Clear draft
      await _deleteDraft();
      if (!mounted) return;
      // Refresh feed
      ref.invalidate(postFeedProvider);
      // Navigate to detail
      if (mounted) context.go('/posts/${p.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final tagsAsync = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Tulis Post' : 'Edit Post'),
        actions: [
          IconButton(
            tooltip: 'Preview',
            icon: Icon(_preview ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _preview = !_preview),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: FilledButton.icon(
              onPressed: _saving ? null : _publish,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_outlined),
              label: const Text('Publikasikan'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16), // Increased padding for better touch targets
        children: [
          // Modern title input
          TextFormField(
            controller: _titleCtrl,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: 'Judul',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => _saveDraft(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 24),
                  error: (e, st) => Text('Kategori gagal: $e'),
                  data: (list) {
                    final options = list.where((e) => e.id != 'all').toList();
                    return InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: options.any((e) => e.id == _categoryId) ? _categoryId : options.first.id,
                          items: options
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _categoryId = v);
                            _saveDraft();
                          },
                          isExpanded: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Modern image button
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: 'Sisipkan Gambar',
                  icon: const Icon(Icons.image_outlined),
                  onPressed: _pickAndInsertImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tags section with better layout
          Text('Tag', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          tagsAsync.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (e, st) => Text('Tag gagal: $e'),
            data: (tags) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in tags)
                    FilterChip(
                      label: Text(t.name),
                      selected: _tagIds.contains(t.id),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _tagIds.add(t.id);
                          } else {
                            _tagIds.remove(t.id);
                          }
                        });
                        _saveDraft();
                      },
                      // Modern chip shape
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _tagIds.contains(t.id) 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.transparent,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Content editor with modern styling
          if (_preview)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Markdown(data: _contentCtrl.text),
            )
          else
            TextFormField(
              controller: _contentCtrl,
              minLines: 12,
              maxLines: 24,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: 'Konten (Markdown didukung)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => _saveDraft(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _saveDraft();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }
}