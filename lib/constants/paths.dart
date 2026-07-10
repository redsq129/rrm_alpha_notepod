/// Base path
///
/// Copyright (C) 2023-2025, Software Innovation Institute
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// Time-stamp: <Thursday 2025-10-02 12:53:12 +1100 Graham Williams>
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

/// Base path for all rrm_alpha data in the Pod.

const String basePath = 'rrm_alpha/data';

/// Path to the shared file repository used for note attachments.
///
/// Files here exist independently of any note - a file's presence in the
/// repository never depends on being attached to something. See
/// [attachmentLogFileName] for the durable attach/detach record.

const String attachmentsBasePath = '$basePath/attachments';

/// Filename of the attachment log resource, which records every
/// attach/detach event (with start and end times) linking a file in
/// [attachmentsBasePath] to a note. Lives directly under [basePath],
/// distinct from `note-*.ttl` files so it is never matched by the
/// `note-` filename prefix filter used to scan for notes.

const String attachmentLogFileName = 'attachment-log.ttl';
