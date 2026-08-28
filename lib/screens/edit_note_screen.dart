import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';

class EditNoteScreen extends StatefulWidget {
  final Note? note;

  const EditNoteScreen({super.key, this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Palette of beautiful pastel colors
  final List<int> _noteColors = const [
    0xFFFFFFFF, // White
    0xFFFFF2D4, // Soft Amber
    0xFFFFE3E3, // Soft Pink
    0xFFE2F0D9, // Soft Green
    0xFFE8F1F5, // Soft Blue
    0xFFF3E8FF, // Soft Purple
    0xFFFDE8E9, // Soft Rose
  ];

  late int _selectedColor;
  int _wordCount = 0;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.note?.color ?? 0xFFFFFFFF;
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
    _updateStats();
    _contentController.addListener(_updateStats);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _updateStats() {
    final text = _contentController.text.trim();
    setState(() {
      _charCount = _contentController.text.length;
      _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<NotesProvider>(context, listen: false);
      
      if (widget.note == null) {
        // Add new
        final newNote = Note(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          timestamp: DateTime.now(),
          color: _selectedColor,
        );
        provider.addNote(newNote);
      } else {
        // Update existing
        final updatedNote = Note(
          id: widget.note!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          timestamp: DateTime.now(),
          color: _selectedColor,
        );
        provider.updateNote(updatedNote);
      }
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى كتابة عنوان الملاحظة أولاً',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _deleteNote() {
    if (widget.note != null) {
      Provider.of<NotesProvider>(context, listen: false).deleteNote(widget.note!);
      Navigator.pop(context);
    }
  }

  void _copyToClipboard() {
    final title = _titleController.text;
    final content = _contentController.text;
    final shareText = "$title\n\n$content";
    
    Clipboard.setData(ClipboardData(text: shareText)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ الملاحظة إلى الحافظة 📋', style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFF202535),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    final backgroundColor = Color(_selectedColor);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF202535)),
        title: Text(
          isEditing ? 'تعديل الملاحظة' : 'إضافة ملاحظة',
          style: GoogleFonts.cairo(
            color: const Color(0xFF202535),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy_all_rounded, color: Color(0xFF202535)),
            tooltip: 'نسخ الملاحظة',
            onPressed: _copyToClipboard,
          ),
          // Delete button
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              tooltip: 'حذف الملاحظة',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text('حذف الملاحظة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    content: Text('هل أنت متأكد من رغبتك في حذف هذه الملاحظة نهائياً؟', style: GoogleFonts.cairo()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteNote();
                        },
                        child: Text('حذف', style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          // Save Icon Button in AppBar
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 4.0),
            child: IconButton(
              icon: const Icon(Icons.check_rounded, color: Color(0xFF4F6DCE), size: 28),
              tooltip: 'حفظ الملاحظة',
              onPressed: _saveNote,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Text Inputs Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Title Input
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF202535),
                        ),
                        decoration: InputDecoration(
                          hintText: 'العنوان',
                          hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'الرجاء كتابة العنوان'
                            : null,
                      ),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 12),
                      // Content Input
                      Expanded(
                        child: TextFormField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: const Color(0xFF202535).withOpacity(0.85),
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText: 'اكتب ملاحظتك هنا...',
                            hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Toolbar containing Color Swatches and Word Count
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color selection label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'اختر لون الخلفية:',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: const Color(0xFF202535).withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Word and Char stats
                      Text(
                        'الكلمات: $_wordCount | الحروف: $_charCount',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xFF202535).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Horizontal Color List
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _noteColors.length,
                      itemBuilder: (context, index) {
                        final colorVal = _noteColors[index];
                        final swatchColor = Color(colorVal);
                        final isSelected = _selectedColor == colorVal;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = colorVal;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: swatchColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4F6DCE)
                                    : Colors.grey.shade300,
                                width: isSelected ? 3.0 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4F6DCE).withOpacity(0.3),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF4F6DCE),
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
