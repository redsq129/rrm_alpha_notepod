/// Service class for the shared file attachment repository.
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
/// Authors: Gareth Davies and The Claudettes 

library;

import 'package:solidpod/solidpod.dart';

import 'package:rrm_alpha/constants/paths.dart';
import 'package:rrm_alpha/services/operations.dart';

/// Service class for browsing the shared file repository
/// ([attachmentsBasePath]) that note attachments are drawn from. Files
/// here exist independently of any note attachment - this only lists
/// what is physically present in the repository.

class AttachmentService with PodOperationsMixin {
  AttachmentService();

  /// Lists every file currently in the attachment repository.
  ///
  /// Returns an empty list if the folder does not exist yet (no files
  /// have ever been uploaded).

  Future<List<String>> listRepositoryFiles() async {
    try {
      final dirUrl = await getDirUrl(attachmentsBasePath);
      final resources = await getResourcesInContainer(dirUrl);

      return resources.files.where((f) => !f.endsWith('.acl')).toList();
    } catch (e) {
      if (!isFileNotFoundError(e) && !isPermissionError(e)) {
        // Error scanning directory.
      }
      return [];
    }
  }
}
