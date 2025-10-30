import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import 'package:forum_alumni/features/auth/application/auth_controller.dart';
import 'package:forum_alumni/features/forum/application/forum_controller.dart';
import 'package:forum_alumni/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:forum_alumni/features/forum/presentation/create_post_screen.dart';
import 'package:forum_alumni/features/forum/presentation/post_detail_screen.dart';
import 'package:forum_alumni/features/profile/presentation/profile_screen.dart';
import 'package:forum_alumni/features/forum/presentation/widgets/post_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = 'home';
  static const String routePath = '/';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load forum data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumNotifierProvider.notifier).fetchInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;
    if (currentOffset >= maxScroll - 200) {
      ref.read(forumNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final forumState = ref.watch(forumNotifierProvider);

    ref.listen<ForumState>(forumNotifierProvider, (previous, next) {
      if (!mounted) return;
      if (next.errorMessage != null &&
          next.errorMessage!.isNotEmpty &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Syneps Academy',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4ECDC4),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: 35,
            height: 35,
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17.5),
              child: Image.asset(
                'assets/images/avatar-1.png',
                width: 35,
                height: 35,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.blue[400],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, authState),
      body: RefreshIndicator(
        onRefresh: () => ref.read(forumNotifierProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Forum Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forum Alumni',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Berbagi cerita dan pengalaman dengan sesama alumni',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              if (forumState.posts.isNotEmpty) ...[
                _buildCreatePrompt(),
                const SizedBox(height: 24),
              ],
              
              // Empty State or Posts
              if (forumState.isLoading && forumState.posts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (forumState.posts.isEmpty)
                _buildEmptyState()
              else
                Column(
                  children: forumState.posts.map((post) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(
                        post: post,
                        onTap: () => context.pushNamed(
                          PostDetailScreen.routeName,
                          pathParameters: {'id': post.id.toString()},
                        ),
                        onLikeTap: () => ref
                            .read(forumNotifierProvider.notifier)
                            .toggleLike(post),
                        onCommentTap: () => context.pushNamed(
                          PostDetailScreen.routeName,
                          pathParameters: {'id': post.id.toString()},
                        ),
                      ),
                    );
                  }).toList(),
                ),
              
              if (forumState.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthState authState) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF4ECDC4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/avatar-1.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  authState.user?.name ?? 'User',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  authState.user?.email ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil Saya'),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(ProfileScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.create),
            title: const Text('Buat Postingan'),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(CreatePostScreen.routeName);
            },
          ),
          if (authState.user?.role == 'admin')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Dashboard Admin'),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed(AdminDashboardScreen.routeName);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 34,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Belum ada postingan',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Jadilah yang pertama berbagi cerita di forum',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _buildCreatePrompt(),
      ],
    );
  }

  Widget _buildCreatePrompt() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openCreatePostSheet,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/images/avatar-1.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.blue[400],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 24,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'Bagikan cerita atau pencapaianmu...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreatePostSheet() async {
    final textController = TextEditingController();
    const maxCharacters = 200;
    XFile? selectedMedia;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      barrierDismissible: true,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final forumState = ref.watch(forumNotifierProvider);
            final isSubmitting = forumState.isCreating;
            final authState = ref.watch(authNotifierProvider);

            return StatefulBuilder(
              builder: (context, setModalState) {
                Future<void> pickImage(ImageSource source) async {
                  final file = await _picker.pickImage(source: source, imageQuality: 85);
                  if (file != null) {
                    setModalState(() => selectedMedia = file);
                  }
                }

                Future<void> showPickOptions() async {
                  if (isSubmitting) return;
                  final source = await showModalBottomSheet<ImageSource>(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (sheetContext) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library_outlined),
                              title: const Text('Pilih dari galeri'),
                              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_camera_outlined),
                              title: const Text('Ambil foto baru'),
                              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (source != null) await pickImage(source);
                }

                Future<void> submit() async {
                  final content = textController.text.trim();
                  if (content.isEmpty && selectedMedia == null) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('Tuliskan cerita atau tambahkan media terlebih dahulu.')),
                      );
                    return;
                  }

                  List<int>? bytes;
                  String? filename;
                  if (selectedMedia != null) {
                    bytes = await selectedMedia!.readAsBytes();
                    filename = selectedMedia!.name.isNotEmpty
                        ? selectedMedia!.name
                        : selectedMedia!.path.split(Platform.pathSeparator).last;
                  }

                  final post = await ref.read(forumNotifierProvider.notifier).createPost(
                        content: content,
                        mediaBytes: bytes,
                        mediaFilename: filename,
                        mediaType: selectedMedia != null ? 'image' : null,
                      );

                  if (!mounted) return;

                  if (post != null) {
                    Navigator.of(dialogContext, rootNavigator: true).pop();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('Postingan berhasil dibuat.')),
                      );
                  } else {
                    final message = ref.read(forumNotifierProvider).errorMessage ??
                        'Gagal membuat postingan. Coba lagi nanti.';
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                  }

                  textController.clear();
                  setModalState(() => selectedMedia = null);
                }

                final canShare = textController.text.trim().isNotEmpty || selectedMedia != null;

                return Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.of(dialogContext, rootNavigator: true).pop(),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Create new post',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: (!canShare || isSubmitting) ? null : submit,
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        'Share',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: canShare ? const Color(0xFF4ECDC4) : Colors.grey[400],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Image.asset(
                                    'assets/images/avatar-1.png',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[400],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                authState.user?.name ?? 'User',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (forumState.errorMessage != null && forumState.errorMessage!.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                forumState.errorMessage!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: textController,
                            onChanged: (_) => setModalState(() {}),
                            minLines: 4,
                            maxLines: 6,
                            inputFormatters: [LengthLimitingTextInputFormatter(maxCharacters)],
                            decoration: InputDecoration(
                              hintText: 'Tulis cerita atau pencapaianmu...',
                              hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${textController.text.length}/$maxCharacters',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ),
                          if (selectedMedia != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(selectedMedia!.path),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: isSubmitting ? null : () => setModalState(() => selectedMedia = null),
                                icon: const Icon(Icons.close, size: 16),
                                label: Text(
                                  'Hapus Media',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: showPickOptions,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[700]),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Add photos/videos',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '*',
                                    style: GoogleFonts.inter(fontSize: 16, color: Colors.red[400]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    textController.dispose();
  }
}
