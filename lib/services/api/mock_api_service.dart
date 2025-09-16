import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/auth/models/user.dart';
import '../../features/posts/models/post.dart';
import '../../features/posts/models/category.dart';
import '../../features/posts/models/tag.dart';
import '../../features/posts/models/comment.dart';
import '../../features/posts/data/posts_remote.dart';

class MockApiService implements IPostsRemote {
  Future<User> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    // Rule mock: gagal jika password bukan 'password' atau email invalid tertentu
    if (password != 'password' || email.endsWith('@invalid.com')) {
      throw Exception('Email atau password salah');
    }
    return User(
      id: 'u_001',
      name: 'Alumni User',
      email: email,
      avatar: 'https://i.pravatar.cc/150?img=3',
      joinDate: DateTime.now().subtract(const Duration(days: 365)),
      bio: 'Anggota Forum Alumni.',
    );
  }

  @override
  Future<List<Category>> listCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _categories;
  }

  @override
  Future<List<Tag>> listTags() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _tags;
  }

  Future<User> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return User(
      id: 'u_001',
      name: 'Alumni User',
      email: 'alumni@example.com',
      avatar: 'https://i.pravatar.cc/150?img=3',
      joinDate: DateTime.now().subtract(const Duration(days: 365)),
      bio: 'Anggota Forum Alumni.',
    );
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (email.endsWith('@taken.com')) {
      throw Exception('Email sudah terdaftar');
    }
    return User(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      avatar: 'https://i.pravatar.cc/150?img=5',
      joinDate: DateTime.now(),
      bio: 'Anggota baru Forum Alumni.',
    );
  }

  // ====== POSTS MOCK ======
  static final _categories = <Category>[
    const Category(id: 'all', name: 'Semua', color: 0xFF607D8B),
    const Category(id: 'info', name: 'Info', color: 0xFF3F51B5),
    const Category(id: 'event', name: 'Event', color: 0xFF009688),
    const Category(id: 'loker', name: 'Lowongan', color: 0xFF795548),
  ];

  static final _tags = <Tag>[
    const Tag(id: 't1', name: 'Umum', color: 0xFF9C27B0),
    const Tag(id: 't2', name: 'Teknologi', color: 0xFF2196F3),
    const Tag(id: 't3', name: 'Karir', color: 0xFFFF9800),
    const Tag(id: 't4', name: 'Kampus', color: 0xFF4CAF50),
  ];

  Category _categoryByIndex(int i) =>
      _categories[(i % (_categories.length - 1)) + 1];
  List<Tag> _tagsByIndex(int i) {
    final a = _tags[i % _tags.length];
    if (i % 3 == 0) return [a];
    final b = _tags[(i + 1) % _tags.length];
    return [a, b];
  }

  @override
  Future<List<Post>> fetchPosts({
    required int page,
    required int limit,
    String? query,
    String? categoryId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final total = 100; // dataset mock
    final start = (page - 1) * limit;
    if (start >= total) return [];
    final end = (start + limit).clamp(0, total);
    final items = <Post>[];
    for (int i = start; i < end; i++) {
      final title = 'Postingan ${i + 1}: Tips Karir Alumni';
      final content =
          '# Judul Post ${i + 1}\n\nIni konten markdown untuk post ${i + 1}.\n\n- Poin 1\n- Poin 2\n\n[Link](https://example.com)';
      final author = User(
        id: 'u_${i % 5}',
        name: 'Alumni ${(i % 5) + 1}',
        email: 'alumni${i % 5}@example.com',
        avatar: 'https://i.pravatar.cc/150?img=${(i % 10) + 1}',
        joinDate: DateTime.now().subtract(Duration(days: 365 + (i % 200))),
        bio: 'Anggota Forum Alumni.',
      );
      final cat = _categoryByIndex(i);
      final tags = _tagsByIndex(i);

      // filter query/category secara sederhana
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        if (!title.toLowerCase().contains(q)) continue;
      }
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        if (cat.id != categoryId) continue;
      }

      items.add(
        Post(
          id: 'p_${i + 1}',
          title: title,
          excerpt: 'Ringkasan singkat dari konten post ${i + 1}.',
          contentMarkdown: content,
          author: author,
          createdAt: DateTime.now().subtract(Duration(hours: i + 1)),
          updatedAt: null,
          category: cat,
          tags: tags,
          votes: (i * 3) % 97,
          userVote: 0,
          commentsCount: (i * 7) % 23,
          bookmarked: (i % 11 == 0),
        ),
      );
    }
    return items;
  }

  @override
  Future<Post> getPost(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final idx = int.tryParse(id.split('_').last) ?? 1;
    final author = User(
      id: 'u_${idx % 5}',
      name: 'Alumni ${(idx % 5) + 1}',
      email: 'alumni${idx % 5}@example.com',
      avatar: 'https://i.pravatar.cc/150?img=${(idx % 10) + 1}',
      joinDate: DateTime.now().subtract(const Duration(days: 400)),
      bio: 'Anggota Forum Alumni.',
    );
    return Post(
      id: id,
      title: 'Postingan Detail $idx',
      excerpt: 'Ringkasan post detail $idx',
      contentMarkdown:
          '# Post $idx\n\nIni detail post dengan konten markdown.\n\n````dart\nvoid main() { print("Hello"); }\n````',
      author: author,
      createdAt: DateTime.now().subtract(Duration(hours: idx + 3)),
      category: _categoryByIndex(idx),
      tags: _tagsByIndex(idx),
      votes: (idx * 3) % 97,
      userVote: 0,
      commentsCount: (idx * 7) % 23,
      bookmarked: idx % 2 == 0,
    );
  }

  @override
  Future<Post> votePost({required String postId, required int vote}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final base = await getPost(postId);
    int newVotes = base.votes;
    if (vote == 1) newVotes += 1;
    if (vote == -1) newVotes -= 1;
    return base.copyWith(votes: newVotes, userVote: vote);
  }

  @override
  Future<Post> bookmarkPost({
    required String postId,
    required bool bookmarked,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final base = await getPost(postId);
    return base.copyWith(bookmarked: bookmarked);
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final user = User(
      id: 'u_c1',
      name: 'Komentator 1',
      email: 'c1@example.com',
      avatar: 'https://i.pravatar.cc/150?img=12',
      joinDate: DateTime.now().subtract(const Duration(days: 100)),
      bio: 'Komentator tetap.',
    );
    final now = DateTime.now();
    return [
      Comment(
        id: 'c_1',
        postId: postId,
        author: user,
        contentMarkdown: 'Komentar pertama.\n\nMantap!',
        createdAt: now.subtract(const Duration(hours: 2)),
        replies: [
          Comment(
            id: 'c_1_1',
            postId: postId,
            parentId: 'c_1',
            author: user.copyWith(name: 'Komentator 2'),
            contentMarkdown: 'Terima kasih!',
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      Comment(
        id: 'c_2',
        postId: postId,
        author: user.copyWith(name: 'Komentator 3'),
        contentMarkdown: 'Ikut nimbrung.',
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  @override
  Future<Comment> addReply({
    required String postId,
    String? parentId,
    required String contentMarkdown,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = User(
      id: 'u_me',
      name: 'Saya',
      email: 'me@example.com',
      avatar: 'https://i.pravatar.cc/150?img=15',
      joinDate: DateTime.now().subtract(const Duration(days: 10)),
      bio: 'Pengguna saat ini.',
    );
    return Comment(
      id: 'c_new_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      parentId: parentId,
      author: user,
      contentMarkdown: contentMarkdown,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Post> createPost({
    required String title,
    required String contentMarkdown,
    String? categoryId,
    List<String> tagIds = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final user = await getProfile();
    final cat = _categories.firstWhere(
      (c) => c.id == (categoryId ?? 'info'),
      orElse: () => _categories[1],
    );
    final tags = _tags.where((t) => tagIds.contains(t.id)).toList();
    return Post(
      id: 'p_new_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      excerpt: contentMarkdown.length > 80
          ? contentMarkdown.substring(0, 80)
          : contentMarkdown,
      contentMarkdown: contentMarkdown,
      author: user,
      createdAt: DateTime.now(),
      category: cat,
      tags: tags,
      votes: 0,
      userVote: 0,
      commentsCount: 0,
      bookmarked: false,
    );
  }

  @override
  Future<Post> updatePost({
    required String id,
    String? title,
    String? contentMarkdown,
    String? categoryId,
    List<String>? tagIds,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final base = await getPost(id);
    final cat = categoryId != null
        ? _categories.firstWhere(
            (c) => c.id == categoryId,
            orElse: () => base.category ?? _categories[1],
          )
        : base.category;
    final tags = tagIds != null
        ? _tags.where((t) => tagIds.contains(t.id)).toList()
        : base.tags;
    return base.copyWith(
      title: title ?? base.title,
      contentMarkdown: contentMarkdown ?? base.contentMarkdown,
      category: cat,
      tags: tags,
      updatedAt: DateTime.now(),
    );
  }

  // ====== END POSTS MOCK ======
}

final mockApiServiceProvider = Provider<MockApiService>(
  (ref) => MockApiService(),
);
