/// A screen for attaching/detaching files in the shared file repository
/// to/from a note.
///
/// Copyright (C) 2026, Software Innovation Institute
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
/// Authors: Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:rrm_alpha/constants/app.dart';
import 'package:rrm_alpha/constants/colours.dart';
import 'package:rrm_alpha/constants/paths.dart';
import 'package:rrm_alpha/models/attachment_record.dart';
import 'package:rrm_alpha/services/attachment_log_service.dart';
import 'package:rrm_alpha/services/attachment_service.dart';

/// Lets the user attach files from the shared repository
/// ([attachmentsBasePath]) to a note, or detach files currently attached
/// to it. Detaching only closes the attachment link (see
/// `AttachmentLogService`) - the file itself is never deleted here.
///
/// This can be used two ways:
/// - Bound to an already-saved note ([noteFileName] non-null): every
///   change is written straight to the attachment log via [onSaved].
/// - Bound to a note still being created/edited ([noteFileName] null,
///   e.g. before the first Save): changes are only tracked in memory and
///   handed back through [onSaved] for the caller to apply once the note
///   itself has been saved and a filename exists.
///
/// Arguments:
/// - [noteFileName] - filename of the note attachments belong to, or
///   `null` if the note has not been saved yet.
/// - [initialAttachedFiles] - file names currently attached to the note
///   (from `AttachmentLogService.activeAttachmentsForNote`, or the
///   in-memory selection carried by the note editor for a new note).
/// - [childPage] - page to return to via [scaffoldController] once
///   done (only used when [noteFileName] is non-null; the modal form
///   pops itself otherwise).
/// - [scaffoldController] - Controller for the Solid scaffold.
/// - [onSaved] - called with the final selected set of file names once
///   the user confirms. When [noteFileName] is non-null this fires after
///   the attachment log has already been updated; when `null`, the
///   caller (the note editor) is responsible for persisting the
///   selection once the note is saved.

class ManageAttachmentsScreen extends StatefulWidget {
  final String? noteFileName;
  final Set<String> initialAttachedFiles;
  final Widget? childPage;
  final SolidScaffoldController? scaffoldController;
  final void Function(Set<String> selectedFiles)? onSaved;

  const ManageAttachmentsScreen({
    super.key,
    this.noteFileName,
    this.initialAttachedFiles = const {},
    this.childPage,
    this.scaffoldController,
    this.onSaved,
  });

  @override
  State<ManageAttachmentsScreen> createState() =>
      _ManageAttachmentsScreenState();
}

class _ManageAttachmentsScreenState extends State<ManageAttachmentsScreen> {
  bool _loading = true;
  bool _saving = false;
  List<String> _repositoryFiles = [];

  /// Baseline used to diff against on Save. For an already-saved note this
  /// comes from the attachment log (fetched in [_load]); for a note still
  /// being created/edited it is whatever the caller passed in.
  late Set<String> _initialActive;
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _initialActive = {...widget.initialAttachedFiles};
    _selected = {...widget.initialAttachedFiles};
    _load();
  }

  Future<void> _load() async {
    final noteFileName = widget.noteFileName;
    final results = await Future.wait([
      AttachmentService().listRepositoryFiles(),
      if (noteFileName != null)
        AttachmentLogService().activeAttachmentsForNote(noteFileName),
    ]);

    if (!mounted) return;
    setState(() {
      _repositoryFiles = results[0] as List<String>;
      if (noteFileName != null) {
        final active = (results[1] as List<AttachmentRecord>)
            .map((r) => r.fileName)
            .toSet();
        _initialActive = active;
        _selected = active;
      }
      _loading = false;
    });
  }

  Future<void> _uploadNewFile() async {
    final before = _repositoryFiles.toSet();

    await SolidFileOperations.uploadFile(
      context,
      attachmentsBasePath,
      allowedExtensions: rrm_alphaUploadConfig.allowedExtensions,
    );

    if (!mounted) return;
    final files = await AttachmentService().listRepositoryFiles();
    final newlyAdded = files.toSet().difference(before);

    if (!mounted) return;
    setState(() {
      _repositoryFiles = files;
      // Newly uploaded files are pre-selected for attaching, for
      // convenience - the user can still uncheck before Save.
      _selected.addAll(newlyAdded);
    });
  }

  Future<void> _download(String fileName) async {
    await SolidFileOperations.downloadFile(
      context,
      fileName,
      attachmentsBasePath,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final noteFileName = widget.noteFileName;
    if (noteFileName != null) {
      final toAttach = _selected.difference(_initialActive);
      final toDetach = _initialActive.difference(_selected);
      final service = AttachmentLogService();

      for (final fileName in toAttach) {
        await service.recordAttach(
          noteFileName: noteFileName,
          fileName: fileName,
        );
      }
      for (final fileName in toDetach) {
        await service.recordDetach(
          noteFileName: noteFileName,
          fileName: fileName,
        );
      }
    }

    if (!mounted) return;

    widget.onSaved?.call(_selected);

    final childPage = widget.childPage;
    if (childPage != null) {
      widget.scaffoldController?.navigateToSubpage(childPage);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _cancel() {
    final childPage = widget.childPage;
    if (childPage != null) {
      widget.scaffoldController?.navigateToSubpage(childPage);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Attachments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              TextButton.icon(
                onPressed: _uploadNewFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload New File'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _repositoryFiles.isEmpty
              ? const Center(
                  child: Text(
                    'No files in the repository yet. '
                    'Use "Upload New File" to add one.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: _repositoryFiles.length,
                  itemBuilder: (context, index) {
                    final fileName = _repositoryFiles[index];
                    return CheckboxListTile(
                      title: Text(fileName),
                      value: _selected.contains(fileName),
                      onChanged: (checked) {
                        setState(() {
                          if (checked ?? false) {
                            _selected.add(fileName);
                          } else {
                            _selected.remove(fileName);
                          }
                        });
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.download),
                        tooltip: 'Download',
                        onPressed: () => _download(fileName),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 5.0,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                onPressed: _saving ? null : _save,
                style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStateProperty.all<Color>(
                        ButtonBackgroundColor.save,
                      ),
                    ),
                label: const Text('SAVE'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.keyboard_backspace),
                onPressed: _saving ? null : _cancel,
                style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStateProperty.all<Color>(
                        ButtonBackgroundColor.back,
                      ),
                    ),
                label: const Text('BACK'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
