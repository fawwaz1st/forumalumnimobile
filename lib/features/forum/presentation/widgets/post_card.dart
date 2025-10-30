import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:forum_alumni/features/forum/data/models/post_model.dart';
import 'package:forum_alumni/core/constants/app_constants.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLikeTap,
    this.onCommentTap,
    this.onShareTap,
    this.onMoreTap,
    this.showActions = true,
    this.isCompact = false,
  });

  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onMoreTap;
  final bool showActions;
  final bool isCompact;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLikeAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.shortAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLikeTap() {
    if (!_isLikeAnimating) {
      setState(() {
        _isLikeAnimating = true;
      });
      
      _animationController.forward().then((_) {
        _animationController.reverse().then((_) {
          setState(() {
            _isLikeAnimating = false;
          });
        });
      });
    }
    
    widget.onLikeTap?.call();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('dd MMM yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}h yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      margin: widget.isCompact 
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.all(widget.isCompact ? 12 : AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Author Info
              Row(
                children: [
                  Hero(
                    tag: 'avatar_${widget.post.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: widget.isCompact ? 18 : 22,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        backgroundImage: widget.post.author.avatarUrl != null 
                            ? CachedNetworkImageProvider(widget.post.author.avatarUrl!)
                            : null,
                        child: widget.post.author.avatarUrl == null
                            ? Text(
                                widget.post.author.name.isNotEmpty 
                                    ? widget.post.author.name[0].toUpperCase() 
                                    : '?',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.author.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: widget.isCompact ? 14 : 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(widget.post.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  if (widget.showActions)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'share':
                            widget.onShareTap?.call();
                            break;
                          case 'report':
                            _showReportDialog(context);
                            break;
                          case 'save':
                            _showSaveDialog(context);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 12),
                              Text('Bagikan'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'save',
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_border),
                              SizedBox(width: 12),
                              Text('Simpan'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined),
                              SizedBox(width: 12),
                              Text('Laporkan'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Content
              Text(
                widget.post.content,
                style: GoogleFonts.inter(
                  fontSize: widget.isCompact ? 14 : 16,
                  height: 1.4,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: widget.isCompact ? 3 : null,
                overflow: widget.isCompact ? TextOverflow.ellipsis : null,
              ),
              
              // Media
              if (widget.post.mediaUrl != null) ...[
                const SizedBox(height: 12),
                Hero(
                  tag: 'media_${widget.post.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.mediaUrl!,
                      width: double.infinity,
                      height: widget.isCompact ? 150 : AppConstants.postImageHeight,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: widget.isCompact ? 150 : AppConstants.postImageHeight,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: widget.isCompact ? 150 : AppConstants.postImageHeight,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gagal memuat gambar',
                              style: GoogleFonts.inter(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              
              if (widget.showActions) ...[
                const SizedBox(height: 12),
                
                // Action Buttons
                Row(
                  children: [
                    // Like Button
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _handleLikeTap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.post.isLiked 
                                        ? Icons.favorite 
                                        : Icons.favorite_border,
                                    color: widget.post.isLiked 
                                        ? Colors.red 
                                        : theme.colorScheme.onSurface.withOpacity(0.6),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.post.likesCount}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: widget.post.isLiked 
                                          ? Colors.red 
                                          : theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Comment Button
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: widget.onCommentTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.post.commentsCount}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Share Button
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: widget.onShareTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Icon(
                          Icons.share,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporkan Postingan'),
        content: const Text('Apakah Anda yakin ingin melaporkan postingan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Laporan berhasil dikirim')),
              );
            },
            child: const Text('Laporkan'),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Postingan berhasil disimpan')),
    );
  }
}
