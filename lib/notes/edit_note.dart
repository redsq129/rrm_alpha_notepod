/// A widget to edit notes owned by the user.
///
// Time-stamp: <Wednesday 2025-07-16 14:37:09 +1000 Graham Williams>
///
/// Copyright (C) 2023-2025, Software Innovation Institute, ANU
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
/// Authors: Anushka Vidanage, Graham Williams, Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:rrm_alpha/models/note.dart';
import 'package:rrm_alpha/notes/new_edit_note.dart';

/// A widget to edit notes owned by the user.
///
/// Editing is done through the same Account Application data-entry form
/// used to create a note (see [NewNote]): supplying [note] as its
/// `existingNote` pre-fills that form from the note's current content and
/// makes Save/Back update the note in place instead of creating a new one.
///
/// Arguments:
///   [note] - is the data of that note.
///   [scaffoldController] - Controller for the Solid scaffold.

class EditNote extends StatelessWidget {
  /// Data object for the selected note.
  final Note note;
  final SolidScaffoldController scaffoldController;

  const EditNote({
    super.key,
    required this.note,
    required this.scaffoldController,
  });

  @override
  Widget build(BuildContext context) {
    return NewNote(
      scaffoldController: scaffoldController,
      existingNote: note,
    );
  }
}
