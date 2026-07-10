/// Service class for the durable attachment log.
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
/// Authors: Gareth and Claude in perfect harmony, 2026

library;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:intl/intl.dart';
import 'package:solidpod/solidpod.dart';

import 'package:rrm_alpha/constants/paths.dart';
import 'package:rrm_alpha/constants/turtle_structures.dart';
import 'package:rrm_alpha/models/attachment_record.dart';
import 'package:rrm_alpha/services/operations.dart';
import 'package:rrm_alpha/utils/turtle/parsing_utils.dart';

/// Timestamp format shared with note created/modified times
/// (`file_helper.dart`'s `modifiedDateTimeStr`).

final DateFormat _attachmentTimeFormat = DateFormat('yyyyMMddTHHmmss');

/// Service class managing the durable attachment log: the record of every
/// file-to-note attach/detach event, independent of the lifecycle of any
/// individual note or file.
///
/// The whole log is stored as a single resource ([attachmentLogFileName])
/// containing one TTL literal holding all records
/// (`AttachmentRecord.encodeAll`/`decodeAll`) - the same "one predicate,
/// one string value" pattern notes use for their content
/// (`genNoteTTLStr`/`TurtleSerializer.noteFromTurtle`).

class AttachmentLogService with PodOperationsMixin {
  AttachmentLogService();

  /// Reads and decodes the current attachment log. Returns an empty list
  /// if the log resource does not exist yet (no attachments have ever
  /// been recorded).

  Future<List<AttachmentRecord>> _readLog() async {
    String ttlContent;
    try {
      ttlContent = await readPod(attachmentLogFileName);
    } catch (e) {
      debugPrint('Attachment log not found, starting a new one: $e');
      return [];
    }

    if (ttlContent.isEmpty || ttlContent.contains('encData')) return [];

    try {
      final triples = TurtleParsingUtils.safeParseTtlToTriple(ttlContent);
      if (triples == null) return [];

      for (final predicates in triples.values) {
        for (final predicate in predicates.keys) {
          if (predicate.contains(attachmentLogPred)) {
            return AttachmentRecord.decodeAll(predicates[predicate] as String);
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing attachment log: $e');
      return [];
    }
  }

  /// Encodes and writes [records] back as the whole attachment log.

  Future<void> _writeLog(List<AttachmentRecord> records) async {
    final ttlStr = genAttachmentLogTTLStr(AttachmentRecord.encodeAll(records));
    await writePod(attachmentLogFileName, ttlStr, overwrite: true);
  }

  /// Records a new active attachment of [fileName] to [noteFileName],
  /// starting now.

  Future<void> recordAttach({
    required String noteFileName,
    required String fileName,
  }) async {
    final records = await _readLog();
    records.add(
      AttachmentRecord(
        noteFileName: noteFileName,
        fileName: fileName,
        attachedTime: _attachmentTimeFormat.format(DateTime.now()),
      ),
    );
    await _writeLog(records);
  }

  /// Closes out the active attachment of [fileName] to [noteFileName],
  /// setting its end time to now. The underlying file is untouched. If no
  /// matching active record is found this is a no-op.

  Future<void> recordDetach({
    required String noteFileName,
    required String fileName,
  }) async {
    final records = await _readLog();
    final now = _attachmentTimeFormat.format(DateTime.now());
    var changed = false;

    final updated = records.map((r) {
      if (!changed &&
          r.isActive &&
          r.noteFileName == noteFileName &&
          r.fileName == fileName) {
        changed = true;
        return r.closedAt(now);
      }
      return r;
    }).toList();

    if (changed) await _writeLog(updated);
  }

  /// Closes out every active attachment belonging to [noteFileName],
  /// setting each end time to now. Used when the note itself is deleted:
  /// the attachment links are ended, but the attached files and the
  /// historical record of the attachments remain.

  Future<void> closeAllForNote(String noteFileName) async {
    final records = await _readLog();
    final now = _attachmentTimeFormat.format(DateTime.now());
    var changed = false;

    final updated = records.map((r) {
      if (r.isActive && r.noteFileName == noteFileName) {
        changed = true;
        return r.closedAt(now);
      }
      return r;
    }).toList();

    if (changed) await _writeLog(updated);
  }

  /// Returns the currently active attachments for [noteFileName].

  Future<List<AttachmentRecord>> activeAttachmentsForNote(
    String noteFileName,
  ) async {
    final records = await _readLog();
    return records
        .where((r) => r.noteFileName == noteFileName && r.isActive)
        .toList();
  }
}
