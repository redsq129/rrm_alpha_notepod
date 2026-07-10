/// rrm_alpha - display all folders from the root of a user's pod.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
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
/// Authors: Tony Chen, Graham Williams (FilePod); ported to rrm_alpha

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:rrm_alpha/constants/app.dart';

/// Browses every folder in the user's POD from the root, reusing solidui's
/// `SolidFile` widget - the same file browser/upload/download/delete widget
/// used for the app's own attachment repository (see `home.dart`), just
/// rooted at the POD root instead of [attachmentsBasePath].

class BrowseFiles extends StatelessWidget {
  const BrowseFiles({super.key});

  @override
  Widget build(BuildContext context) {
    return const SolidFile(
      currentPath: SolidFile.podRoot,
      friendlyFolderName: 'All Files and Folders',
      uploadConfig: rrm_alphaUploadConfig,
    );
  }
}
