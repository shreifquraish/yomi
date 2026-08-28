import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/notes_provider.dart';
import '../models/note_model.dart';
import 'edit_note_screen.dart';
import 'login_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _searchQuery = '';
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  // Selection Mode State Variables
  bool _isSelectionMode = false;
  final Set<int> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).fetchNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    }
  }

  void _deleteNoteWithUndo(BuildContext context, NotesProvider provider, Note note) {
    provider.deleteNote(note);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حذف "${note.title}"',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF202535),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'تراجع',
          textColor: const Color(0xFF4F6DCE),
          onPressed: () {
            provider.undoDelete();
          },
        ),
      ),
    );
  }

  void _deleteSelectedNotes(NotesProvider provider) {
    final selectedNotes = provider.notes.where((note) => _selectedNoteIds.contains(note.id)).toList();
    if (selectedNotes.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف الملاحظات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف ${selectedNotes.length} ملاحظات؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteMultipleNotes(selectedNotes);
              final count = selectedNotes.length;
              setState(() {
                _isSelectionMode = false;
                _selectedNoteIds.clear();
              });

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم حذف $count ملاحظات',
                    style: GoogleFonts.cairo(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF202535),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  action: SnackBarAction(
                    label: 'تراجع',
                    textColor: const Color(0xFF4F6DCE),
                    onPressed: () {
                      provider.undoDelete();
                    },
                  ),
                ),
              );
            },
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedNoteIds.contains(id)) {
        _selectedNoteIds.remove(id);
        if (_selectedNoteIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNoteIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final provider = Provider.of<NotesProvider>(context);

    // Filter notes based on search query
    final filteredNotes = provider.notes.where((note) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF202535)),
                tooltip: 'إلغاء التحديد',
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedNoteIds.clear();
                  });
                },
              )
            : null,
        title: _isSelectionMode
            ? Text(
                'تم تحديد ${_selectedNoteIds.length}',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF202535),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            : Text(
                'يومي',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF202535),
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  letterSpacing: 0.5,
                ),
              ),
        actions: _isSelectionMode
            ? [
                // Delete selected action
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 26),
                  tooltip: 'حذف المحدد',
                  onPressed: () => _deleteSelectedNotes(provider),
                ),
                const SizedBox(width: 8),
              ]
            : [
                // Grid/List Toggle
                IconButton(
                  icon: Icon(
                    _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    color: const Color(0xFF202535),
                  ),
                  tooltip: _isGridView ? 'عرض كقائمة' : 'عرض كشبكة',
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
                // User profile image with popup menu
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        _logout();
                      }
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null,
                              child: user?.photoURL == null
                                  ? Text(
                                      user?.displayName?.substring(0, 1) ?? 'ي',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user?.displayName ?? 'مستخدم يومي',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF202535),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user?.email ?? '',
                                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'تسجيل الخروج',
                              style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Hero(
                      tag: 'profile_pic',
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF4F6DCE).withOpacity(0.2),
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Text(
                                user?.displayName?.substring(0, 1) ?? 'ي',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF4F6DCE),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header (Only visible if not in Selection Mode for clean look)
          if (!_isSelectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أهلاً، ${user?.displayName?.split(' ').first ?? 'مستخدمنا'} 👋',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF202535),
                    ),
                  ),
                  Text(
                    provider.notes.isEmpty
                        ? 'لا توجد ملاحظات مسجلة بعد'
                        : 'لديك ${provider.notes.length} ملاحظات في يومي',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: const Color(0xFF202535).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          if (!_isSelectionMode) const SizedBox(height: 12),
          // Modern Search Bar (Only visible if not in Selection Mode)
          if (!_isSelectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF202535).withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: GoogleFonts.cairo(fontSize: 15, color: const Color(0xFF202535)),
                  decoration: InputDecoration(
                    hintText: 'البحث في ملاحظاتك وقوائمك...',
                    hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),
          if (!_isSelectionMode) const SizedBox(height: 16),
          // Notes Content Area
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4F6DCE),
                      strokeWidth: 3,
                    ),
                  )
                : filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : _buildNotesGridOrList(filteredNotes, provider),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null // Hide Floating Action Button during Selection Mode
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF4F6DCE),
              elevation: 4,
              highlightElevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const EditNoteScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(0, 1), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeInOutCubic)),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              label: Text(
                'ملاحظة جديدة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4F6DCE).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.note_alt_rounded,
                size: 72,
                color: Color(0xFF4F6DCE),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty ? 'لا توجد نتائج بحث مطابقة' : 'ابدأ كتابة ملاحظاتك',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF202535),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'جرّب البحث بكلمات أخرى أو تحقق من الإملاء'
                  : 'احتفظ بأفكارك، مهامك اليومية، وملاحظاتك الشخصية هنا بشكل آمن وسهل.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: const Color(0xFF202535).withOpacity(0.5),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesGridOrList(List<Note> notes, NotesProvider provider) {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildNoteCard(note, provider);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildNoteCard(note, provider);
        },
      );
    }
  }

  Widget _buildNoteCard(Note note, NotesProvider provider) {
    final noteColor = Color(note.color);
    final isWhiteBg = note.color == 0xFFFFFFFF;
    final isSelected = _selectedNoteIds.contains(note.id);

    // Date formatting
    final formattedDate = DateFormat('dd MMM yyyy - hh:mm a', 'ar_AE').format(note.timestamp);

    // Build the Card Widget
    Widget cardWidget = Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF4F6DCE)
              : (isWhiteBg ? Colors.grey.shade200 : noteColor.withOpacity(0.5)),
          width: isSelected ? 2.5 : 1.5,
        ),
      ),
      color: noteColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_isSelectionMode && note.id != null) {
            _toggleSelection(note.id!);
          } else {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => EditNoteScreen(note: note),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(begin: const Offset(1, 0), end: Offset.zero)
                          .chain(CurveTween(curve: Curves.easeInOutCubic)),
                    ),
                    child: child,
                  );
                },
              ),
            );
          }
        },
        onLongPress: () {
          if (note.id != null) {
            setState(() {
              _isSelectionMode = true;
              _selectedNoteIds.add(note.id!);
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF202535),
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Conditional Indicator: Checkbox if in Selection Mode, color indicator if not
                  if (_isSelectionMode)
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? const Color(0xFF4F6DCE) : Colors.grey.shade400,
                      size: 22,
                    )
                  else if (!isWhiteBg)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF202535).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Snippet of note content
              Text(
                note.content.isEmpty ? 'ملاحظة فارغة' : note.content,
                style: GoogleFonts.cairo(
                  color: const Color(0xFF202535).withOpacity(0.65),
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: _isGridView ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              // Timestamp
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: const Color(0xFF202535).withOpacity(0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF202535).withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Disable Swipe-to-delete during selection mode for safety and clear user UX
    if (_isSelectionMode) {
      return cardWidget;
    }

    return Dismissible(
      key: Key('note_dismiss_${note.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        _deleteNoteWithUndo(context, provider, note);
      },
      child: cardWidget,
    );
  }
}
