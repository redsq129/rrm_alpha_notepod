/// App-wide constants.
///
// Time-stamp: <Thursday 2026-04-30 17:22:33 +1000 Graham Williams>
///
/// Copyright (C) 2023-2026, Software Innovation Institute
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

// Add the library directive as we have doc entries above. We publish the above
// meta doc lines in the docs.

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart' show SolidInviteOthersConfig;

const String applicationRepo = 'https://github.com/anusii/rrm_alpha';
const String appChangeLog =
    'https://github.com/anusii/rrm_alpha/blob/dev/CHANGELOG.md';
const String defWebID = 'https://pods.solidcommunity.au';
const String topBarTitle = 'rrm_alpha';
const String shortTitle = 'rrm_alpha data wallet';
const String longTitle = 'rrm_alpha\nTenant Information for use in the residential rental market';

const String appOwner = '''© 2025 - 2026 Software Innovation Institute''';

const String aboutText = '''

          rrm_alpha is a private and shareable data manager that stores a record of tenant information
          for use in the residential rental market. This information is encrypted in a personal Solid Pod, so your data stays
          under your control. Your Solid Pod can be hosted on any Solid
          server and being encrypted it is protected against casual access by
          anyone, including the server administrators.

          ### Key features

          - Create, edit and delete private encrypted tenant information
          - Share information with other Solid Pod owners
          - Browse all accessible information or just your own
          - Full markdown rendering and editing
          - Selectable text for easy copying
          - Backup and restore information as JSON
          - Security key management for encrypted data
          - Theme switching (light / dark / system)

          For more information, visit the
          [rrm_alpha](https://github.com/anusii/rrm_alpha) GitHub repository
          and our [Australian Solid Community](https://solidcommunity.au)
          web site.

          ''';

const String appDir = 'rrm_alpha';

const AssetImage backgroundImg =
    AssetImage('assets/images/rrm_alpha-background.jpg');
const AssetImage logoImg = AssetImage('assets/images/rrm_alpha.png');

//const kDefaultPadding = 20.0;
//const double buttonBorderRadius = 5;
//const double standardSpace = 20.0;
const double badListItemHeight = 68.0;

double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
//double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

const nonReadableNoteMsg =
    'You do not have read access to this Tenant Information and therefore cannot view that. However, you can delete it or share it with others.';

//const noNotesMsg = 'You do not have any notes yet!';

// SizedBox standardHeight() {
//   return const SizedBox(
//     height: standardSpace / 2,
//   );
// }

const double desktopWidthThreshold = 960;

// Text style of page titles
const titleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.bold,
);

// Text style for metadata
const metadataTextStyle = TextStyle(
  fontSize: 12,
);

// Text style for advice
const adviceStyle = TextStyle(
  fontSize: 13,
);

// Titles for nav widgets to pages
const String newNoteTitle = 'New Tenant Information Record';
const String newNoteToolTip = 'Create a new Tenant Information Record';
const String myNotesTitle = 'My Tenant Information';
const String myNotesExplanation = 'owned by me';
const String myNotesToolTip = 'Go to the Tenant Information owned by me';
const String combinedNotesTitle = 'Tenant Information';
const String combinedNotesExplanation = 'accessible to me';
const String combinedNotesToolTip = 'Go to the Tenant Information accessible to me';

const String importExportTitle = 'Backup';
const String importExportToolTip = '**Backup**\n\n'
    'Back up and restore all Tenant Information, view your Information as a PDF, '
    'or import and export.';

/// Note list messages
class NoteListMsg {
  /// Message displayed when corrupt files found
  static const String badFilesFound = 'Corrupt tenant information files present';

  /// Message displayed when inaccessible notes are found (deleted without
  /// revoking access, or encrypted with an earlier key pair)
  static const String inaccessibleNotesFound =
      'Inaccessible tenant information present without \'revoke\' entry in log';

  /// Message displayed when no notes found in user's Pod
  static const String noNotes = 'No Tenant Information Records yet!';

  /// Advises user to write their first note
  static const String writeFirstNote = 'Write your first record of Tenant Information details';
}

/// Note action messages
class Msg {
  /// Note saving message
  static const String savingNote = 'Saving the Tenant Information Record!';

  /// Note deleting message
  static const String deletingNote = 'Deleting the Tenant Information Record!';

  /// Confirm delete note message
  static const String confirmDelete =
      'Are you sure you want to delete this Tenant Information Record?';

  /// Confirm delete multiple notes message
  static const String confirmDeleteMultiple =
      'Are you sure you want to delete these Tenant Information Records?';

  /// Note deleting message
  static const String revokingNote = 'Revoking access!';

  /// Confirm revoke access to note message
  static const String confirmRevoke =
      'Are you sure you want to revoke access to this Tenant Information Record?';

  /// Confirm revoke access to multiple notes message
  static const String confirmRevokeMultiple =
      'Are you sure you want to revoke access to these Tenant Information Records?';

  /// Please confirm message
  static const String plsConfirm = 'Please Confirm';
}

/// Error messages for errors occuring on note actions
class ErrMsg {
  /// No changes to note error.
  static const String noChanges = 'You have no new changes!';

  /// No note content.
  static const String noContent = 'Please enter some Tenant Information details.';

  /// Invalid note name.
  static const String invalidName =
      'Tenant Information name validation failed! Try using a different name.';

  /// Error message when fails to save note file to POD
  static const String saveFailed =
      'Failed to store the Tenant Information record in your POD. Try again!';

  /// Unsaved changes found
  static const String unsavedChanges = 'Unsaved changes found!';
}

class NoteIconSize {
  static const double width = 50;
  static const double height = 50;
  static const double twoIconWidth = (width * 2) + gap;
  static const double gap = 15;
}

// EdgeInsets for metadata block on view notes
const EdgeInsets metadataPadding = EdgeInsets.fromLTRB(15, 5, 10, 0);

/// Button shape decoration for list pages
ShapeDecoration buttonShapeList =
    const ShapeDecoration(color: Colors.grey, shape: CircleBorder());

/// Public URL where rrm_alpha is hosted. Used by the Invite Others
/// feature to send a working link to the recipient.

const String appUrl = 'https://rrm_alpha.solidcommunity.au';

/// Application-wide Invite Others configuration shared by the
/// AppBar share button, the App Info dialogue, and the grant
/// permissions fallback so that users can invite others to set up
/// their POD and try rrm_alpha.

const SolidInviteOthersConfig inviteOthersConfig = SolidInviteOthersConfig(
  applicationName: 'rrm_alpha',
  appUrl: appUrl,
  appDescription: 'read, write, and share encrypted Tenant Information Records stored on your '
      'own personal online data store',
  messageTemplate: '''
You might like to try the {appName} app, available online here:

{appUrl}

Signing into {appName} will set up your data vault so you can create and share private, encrypted Tenant Information Records with other Solid users.''',
  subject: 'Try the rrm_alpha app on your Solid POD',
  tooltip: '''

  **Invite Others**

  Tap to invite someone else to try rrm_alpha. You can copy the
  invitation to the clipboard or share it through any messaging app
  installed on your device.

  ''',
);
