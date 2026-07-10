/// A read-only preview of a note's underlying JSON record.
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

library;

import 'dart:convert';

import 'package:flutter/material.dart';

/// Shows [json] pretty-printed, read-only, labelled "JSON" - so the current
/// fields of an existing note can be reviewed before it is amended. Renders
/// nothing when [json] is empty. Falls back to the raw string if [json]
/// isn't valid JSON.

class NoteJsonPreview extends StatelessWidget {
  final String json;

  const NoteJsonPreview({super.key, required this.json});

  String get _pretty {
    try {
      final decoded = jsonDecode(json);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (e) {
      return json;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (json.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JSON',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _pretty,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
