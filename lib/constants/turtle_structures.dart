/// Individual's POD content variables.
///
/// Copyright (C) 2023 Software Innovation Institute, Australian National University
///
/// License: GNU General Public License, Version 3 (the "License")
/// https://opensource.org/license/gpl-3-0
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
/// Authors: Anushka Vidanage, Jess Moore

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

// const myNotesDir = 'mynotes';
const noteFileNamePrefix = 'note-';

// IRIs (Internationalized Resource Identifiers).
//
// 20251001 gjw Split the string to avoid lychee link check excluded.
//
// 20251001 jess The exclusions could be made as special cases in ci.yaml,
// flutter.mk.
//
// 20251001 gjw But those are tempalted files and checking for special cases
// there is awkward.

String rrm_alphaTerms = 'https://solidcommunity.au/' 'predicates/terms#';

String createdDateTimePred = 'createdDateTime';
String createdDateTimePredErr = 'createdDateERROR';
String modifiedDateTimePred = 'modifiedDateTime';
String noteContentPred = 'noteContent';
String noteTitlePred = 'noteTitle';
//String encNoteContentPred = 'encNoteContent';
String mePred = ':me';
// 20251006 jess Keep meKey as ref, even though mePred is shorthand
// String meKey = '#me';

// All notes details
String noteUrlPred = 'noteUrl';
String noteFileNamePred = 'noteFileName';
String noteOwnerPred = 'noteOwner';
String contentPred = 'content';
String isSelectedPred = 'isSelected';

// Shared notes details
String sharedTimePred = 'sharedTime';
String permissionGranterPred = 'permissionGranter';
String permissionRecepientPred = 'permissionRecepient';
String permissionTypePred = 'permissionType';
String permissionListPred = 'permissionList';

// Attachment log details
String attachmentLogPred = 'attachmentLog';

// Prefix applied to the predicate name of each individually-flattened data
// field triple emitted alongside the whole-blob noteContent field (see
// [flattenJsonForTriples] and [genNoteTTLStr]), so they're namespaced apart
// from the four fixed note predicates above.
String dataFieldPredPrefix = 'data_';

/// Recursively flattens a decoded JSON map into a single-level map keyed by
/// underscore-joined paths (e.g. `customer.face_image.url` becomes
/// `customer_face_image_url`), so each leaf value can be emitted as its own
/// RDF triple. Non-map leaf values are stringified with `'$value'`, which
/// matches their JSON text form for String/num/bool. Null values are
/// skipped (absent optional fields).

Map<String, String> flattenJsonForTriples(
  Map<String, dynamic> json, [
  String prefix = '',
]) {
  final result = <String, String>{};
  json.forEach((key, value) {
    final path = prefix.isEmpty ? key : '${prefix}_$key';
    if (value == null) return;
    if (value is Map<String, dynamic>) {
      result.addAll(flattenJsonForTriples(value, path));
    } else {
      result[path] = '$value';
    }
  });
  return result;
}

// Set up encrypted note file content
String genNoteTTLStr(
  String createdTimeStr,
  String updatedTimeStr,
  String noteTitle,
  String noteContent, {
  Map<String, String>? dataFields,
}) {
  final statements = <String>[
    'a foaf:PersonalProfileDocument',
    'terms:title "Note"',
    'rrm_alphaTerms:$createdDateTimePred "$createdTimeStr"',
    'rrm_alphaTerms:$modifiedDateTimePred "$updatedTimeStr"',
    'rrm_alphaTerms:$noteTitlePred "$noteTitle"',
    'rrm_alphaTerms:$noteContentPred "$noteContent"',
    if (dataFields != null)
      for (final entry in dataFields.entries)
        'rrm_alphaTerms:$dataFieldPredPrefix${entry.key} "${entry.value}"',
  ];
  final body = statements.map((s) => '          $s').join(';\n');

  String noteTTLStr = '''@prefix : <#>.
      @prefix foaf: <$foaf>.
      @prefix terms: <$terms>.
      @prefix rrm_alphaTerms: <$rrm_alphaTerms>.
      $mePred
$body.''';

  // 20251008 jm: code to generate a corrupt note
  // for testing purposes only.
  // Generates TTL with incorrect predicate
  String noteTTLStrErr = '';
  // String noteTTLStrErr = '''@prefix : <#>.
  //     @prefix foaf: <$foaf>.
  //     @prefix terms: <$terms>.
  //     @prefix rrm_alphaTerms: <$rrm_alphaTerms>.
  //     $mePred
  //         a foaf:PersonalProfileDocument;
  //         terms:title "Note";
  //         rrm_alphaTerms:$createdDateTimePredErr "$createdTimeStr";
  //         rrm_alphaTerms:$modifiedDateTimePred "$updatedTimeStr";
  //         rrm_alphaTerms:$noteTitlePred "$noteTitle";
  //         rrm_alphaTerms:$noteContentPred "$noteContent".''';

  final String chosenTTL;
  // // Choose erroneous TTL
  // chosenTTL = noteTTLStrErr;
  // Choose correct TTL
  chosenTTL = noteTTLStr;

  if (chosenTTL == noteTTLStrErr) {
    debugPrint(
      'Writing note file using incorrect predicate $createdDateTimePredErr',
    );
  } else if (chosenTTL == noteTTLStr) {
    debugPrint('Writing note file using correct predicates');
  }

  return chosenTTL;
  // return noteTTLStr;
}

/// Set up attachment log file content.
///
/// [encodedLog] is the whole attachment log (see
/// `AttachmentRecord.encodeAll`) as a single delimited string - none of
/// its possible characters (sanitised filenames, `yyyyMMddTHHmmss`
/// timestamps, and the `|`/`;;` delimiters) can contain a `"`, so it is
/// safe to embed directly in a single-line TTL string literal, the same
/// way ciphertext note content is embedded in [genNoteTTLStr].

String genAttachmentLogTTLStr(String encodedLog) {
  return '''@prefix : <#>.
      @prefix foaf: <$foaf>.
      @prefix terms: <$terms>.
      @prefix rrm_alphaTerms: <$rrm_alphaTerms>.
      $mePred
          a foaf:PersonalProfileDocument;
          terms:title "Attachment Log";
          rrm_alphaTerms:$attachmentLogPred "$encodedLog".''';
}
