import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/db_helper.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> fetchNotes() async {
    _isLoading = true;
    notifyListeners();

    _notes = await DatabaseHelper.instance.readAllNotes();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    await DatabaseHelper.instance.create(note);
    await fetchNotes();
  }

  Future<void> updateNote(Note note) async {
    await DatabaseHelper.instance.update(note);
    await fetchNotes();
  }

  List<Note> _recentlyDeletedNotes = [];

  Future<void> deleteNote(Note note) async {
    _recentlyDeletedNotes = [note];
    if (note.id != null) {
      await DatabaseHelper.instance.delete(note.id!);
      await fetchNotes();
    }
  }

  Future<void> deleteMultipleNotes(List<Note> notes) async {
    _recentlyDeletedNotes = List.from(notes);
    for (final note in notes) {
      if (note.id != null) {
        await DatabaseHelper.instance.delete(note.id!);
      }
    }
    await fetchNotes();
  }

  Future<void> undoDelete() async {
    if (_recentlyDeletedNotes.isNotEmpty) {
      for (final note in _recentlyDeletedNotes) {
        final noteToRestore = Note(
          title: note.title,
          content: note.content,
          timestamp: note.timestamp,
          color: note.color,
        );
        await DatabaseHelper.instance.create(noteToRestore);
      }
      _recentlyDeletedNotes.clear();
      await fetchNotes();
    }
  }
}

