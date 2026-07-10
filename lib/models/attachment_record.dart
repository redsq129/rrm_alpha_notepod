/// Data model for a note-attachment audit record.
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

/// Field separator used within a single encoded log line. Safe because
/// neither note filenames (`note-yyyyMMddTHHmmss.ttl`), sanitised
/// attachment filenames (`[a-zA-Z0-9._-]` plus `.enc.ttl`), nor
/// `yyyyMMddTHHmmss` timestamps can contain it.

const String _fieldSep = '|';

/// Record separator used to encode a whole log as a single string.

const String recordSep = ';;';

/// A single episode of a file being attached to a note: a file in the
/// shared attachment repository linked to a note, with a start time
/// ([attachedTime]) and, once unlinked, an end time ([detachedTime]).
///
/// The file itself is never deleted by ending an attachment - only the
/// link between file and note is closed. The record is kept (not removed)
/// after being closed, so it forms a durable audit trail that survives
/// deletion of the note it refers to.

class AttachmentRecord {
  /// Filename of the note this attachment belongs to.
  final String noteFileName;

  /// Filename of the attached file within the repository
  /// (`attachmentsBasePath`).
  final String fileName;

  /// When the attachment started, formatted `yyyyMMddTHHmmss`.
  final String attachedTime;

  /// When the attachment ended, formatted `yyyyMMddTHHmmss`. `null` (or
  /// empty) means the attachment is still active.
  final String? detachedTime;

  const AttachmentRecord({
    required this.noteFileName,
    required this.fileName,
    required this.attachedTime,
    this.detachedTime,
  });

  /// Whether this attachment is still in effect (has not been detached).

  bool get isActive => detachedTime == null || detachedTime!.isEmpty;

  /// Returns a copy of this record with [detachedTime] set, closing it out.

  AttachmentRecord closedAt(String detachedTime) => AttachmentRecord(
        noteFileName: noteFileName,
        fileName: fileName,
        attachedTime: attachedTime,
        detachedTime: detachedTime,
      );

  /// Encodes this record as a single delimited line.

  String toLine() =>
      [noteFileName, fileName, attachedTime, detachedTime ?? '']
          .join(_fieldSep);

  /// Parses a single delimited line back into a record. Returns `null` if
  /// the line is malformed (e.g. from a future log format).

  static AttachmentRecord? fromLine(String line) {
    final parts = line.split(_fieldSep);
    if (parts.length != 4) return null;
    return AttachmentRecord(
      noteFileName: parts[0],
      fileName: parts[1],
      attachedTime: parts[2],
      detachedTime: parts[3].isEmpty ? null : parts[3],
    );
  }

  /// Encodes a whole list of records as a single string, suitable for
  /// storing as one TTL literal.

  static String encodeAll(List<AttachmentRecord> records) =>
      records.map((r) => r.toLine()).join(recordSep);

  /// Decodes a whole log string (as produced by [encodeAll]) back into a
  /// list of records. Malformed lines are skipped.

  static List<AttachmentRecord> decodeAll(String encoded) {
    if (encoded.trim().isEmpty) return [];
    return encoded
        .split(recordSep)
        .where((line) => line.isNotEmpty)
        .map(AttachmentRecord.fromLine)
        .whereType<AttachmentRecord>()
        .toList();
  }
}
