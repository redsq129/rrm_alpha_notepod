/// A stateful widget for creating a new note.
///
// Time-stamp: <Wednesday 2025-07-16 14:43:37 +1000 Graham Williams>
///
/// Copyright (C) 2023-2025, Software Innovation Institute
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams, Anushka Vidanage, Jess Moore

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:solidui/solidui.dart';

import 'package:rrm_alpha/notes/list_my_notes_screen.dart';
import 'package:rrm_alpha/widgets/note_edit_scroll_view.dart';

/// A [Stateful] widget for creating a new note.
///
/// Parameters:
///   [scaffoldController] - Controller for the Solid scaffold.

const String jsonData = '''"customer": {
        "bank_id": "gh.29.uk",
        "customer_id": "7uy8a7e4-6d02-40e3-a129-0b2bf89de8uh",
        "customer_number": "5987953",
        "legal_name": "Eveline Tripman",
        "mobile_phone_number": "+44 07972 444 876",
        "email": "felixsmith@example.com",
        "address": {
          "street": "123 Main Street",
          "city": "London",
          "postcode": "SW1A 1AA"
        }
      }''';

class NewNote extends StatefulWidget {
  final SolidScaffoldController scaffoldController;

  /// Optional title to pre-fill when creating a note from the search bar.
  final String? initialTitle;
  
  const NewNote({
    super.key,
    required this.scaffoldController,
    this.initialTitle, 
  });

  @override
  NewNoteState createState() => NewNoteState();
}

class NewNoteState extends State<NewNote> {
  final formKey = GlobalKey<FormBuilderState>();

  TextEditingController? _textController;

  /// Scroll controller for single child scroll view.
  late final ScrollController _scrollController;

  /// Scaffold controller
  late final SolidScaffoldController _scaffoldController;

  /// Focus node for note title text field.
  late final FocusNode _focusTitle;

  /// Focus node for note content text field.
  late final FocusNode _focusContent;

  /// Initialise note content text string.
  String data = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: jsonData);
    _scrollController = ScrollController();
    _scaffoldController = widget.scaffoldController;

    // Start listening to changes.
    _textController!.addListener(_renderMarkdown);
    // Focus node for the title text field
    // If 'TAB' key press, move to note content text field
    _focusTitle = FocusNode(
      onKeyEvent: (FocusNode node, KeyEvent evt) {
        if (evt.logicalKey == LogicalKeyboardKey.tab) {
          if (evt is KeyDownEvent) {
            // Move focus
            _focusContent.requestFocus();
          }
          return KeyEventResult.handled;
        } else {
          return KeyEventResult.ignored;
        }
      },
    );
    // Focus node for the note content markdown editor; TAB takes us back to the title text field
    _focusContent = FocusNode(
      onKeyEvent: (FocusNode node, KeyEvent evt) {
        if (evt.logicalKey == LogicalKeyboardKey.tab) {
          if (evt is KeyDownEvent) {
            // Move focus
            _focusTitle.requestFocus();
          }
          return KeyEventResult.handled;
        } else {
          return KeyEventResult.ignored;
        }
      },
      );
    // To enable the ENTER => SAVE functionality within a note replace the above
    // line with the following. For now we will stay with current
    // behaviour. (20250714 gjw).
    //
    // _focusContent = FocusNode(
    //   onKeyEvent: (FocusNode node, KeyEvent evt) {
    //     if (!HardwareKeyboard.instance.isShiftPressed &&
    //         evt.logicalKey.keyLabel == 'Enter') {
    //       if (evt is KeyDownEvent) {
    //         // Save note when enter (not shift-enter) pressed
    //         NoteFileHelper().saveNote(context, _textController!, formKey);
    //       }
    //       return KeyEventResult.handled;
    //     } else {
    //       return KeyEventResult.ignored;
    //     }
    //   },
    // );
  }

  @override
  void dispose() {
    _textController!.dispose(); // Dispose the TextEditingController
    _scrollController.dispose(); // Dispose the ScrollController
    _focusTitle.dispose(); // Dispose the title focus node
    _focusContent.dispose(); // Dispose the content focus node
    super.dispose();
  }

  void _renderMarkdown() {
    setState(() {
      data = _textController!.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NoteEditScrollView(
      formKey: formKey,
      textController: _textController,
      scaffoldController: _scaffoldController,
      focusTitle: _focusTitle,
      focusContent: _focusContent,
      noteTitle: widget.initialTitle,
      childPage: ListMyNotesScreen(
        scaffoldController: _scaffoldController,
      ),
      data: data,
    );
  }
}
