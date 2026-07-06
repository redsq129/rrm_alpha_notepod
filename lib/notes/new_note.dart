/// A stateful widget for creating a new note.
///
// Time-stamp: <Wednesday 2025-07-16 14:43:37 +1000 Graham Williams>
///
/// Copyright (C) 2023-2025, Software Innovation Institute
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
/// Authors: Graham Williams, Anushka Vidanage, Jess Moore

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:solidui/solidui.dart';

import 'package:notepod/constants/turtle_structures.dart';
import 'package:notepod/notes/list_my_notes_screen.dart';
import 'package:notepod/widgets/note_edit_scroll_view.dart';
import 'package:notepod/widgets/note_save_button.dart';

/// A [Stateful] widget for creating a new note.
///
/// Parameters:
///   [scaffoldController] - Controller for the Solid scaffold.
///
/// This widget now also drives a structured data-entry form for capturing
/// an Account Application record as described by the Proto PI JSON schema
/// (referred to below as "y"). The user fills in the individual fields
/// defined by "y" through a [FormBuilder] form. When the user finishes
/// entering the data, the collected values are assembled into a single
/// JSON record that conforms to the shape of "y" - this completed record
/// is referred to as "z". "z" then replaces whatever text/content the
/// user had been editing in the note, so the note's content becomes the
/// completed application JSON record.

/// Allowed values for `customer.relationship_status`, taken directly from
/// the "y" schema's enum for that field.

const List<String> relationshipStatusOptions = [
  'single',
  'married',
  'divorced',
  'widowed',
  'partnered',
  'other',
];

/// Date display/entry format for the applicant's jurisdiction (Australia):
/// day, then month, then year, with no time component - dates in "y" never
/// need a time of day.

final DateFormat auDateFormat = DateFormat('dd MMMM yyyy');

/// Format used when writing dates into the completed "z" JSON record:
/// date-only, ISO 8601 (`yyyy-MM-dd`), with no time component.

final DateFormat isoDateOnlyFormat = DateFormat('yyyy-MM-dd');

class StyledTextEditingController extends TextEditingController {
    static final RegExp emailRegex = RegExp(
  r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
);
    
    // Define the patterns to style
    static const List<String> patterns = [
        r'{{\s*\w+\s*}}', // Template variables
        r'#\w+',          // Hashtags
        r'https?://\S+', // URL
   ];

    @override
    TextSpan buildTextSpan({
      required BuildContext context,
      TextStyle? style,
      required bool withComposing,
    }) {
      return TextSpan(
        style: style,
        text: text,
      );
    }
}

class NewNote extends StatefulWidget {
  final SolidScaffoldController scaffoldController;

  /// Optional title to pre-fill when creating a note from the search bar.
  final String? initialTitle;
  
  const NewNote({
    super.key,
    required this.scaffoldController,
    this.initialTitle, 
  });

  @override
  NewNoteState createState() => NewNoteState();
}

class NewNoteState extends State<NewNote> {
  final formKey = GlobalKey<FormBuilderState>();

  /// Key for the Account Application data-entry form ("y").

  final GlobalKey<FormBuilderState> _appFormKey =
      GlobalKey<FormBuilderState>();

  StyledTextEditingController? _textController;

  /// Scroll controller for single child scroll view.
  late final ScrollController _scrollController;

  /// Scaffold controller
  late final SolidScaffoldController _scaffoldController;

  /// Focus node for note title text field.
  late final FocusNode _focusTitle;

  /// Focus node for note content text field.
  ///
  /// Content is no longer directly editable by the user - it is only
  /// ever produced by completing the Account Application form - so this
  /// node is created with `canRequestFocus: false`, meaning the content
  /// field can never receive keyboard focus or typed input. The title
  /// field remains fully editable as before.
  late final FocusNode _focusContent;

  /// Initialise note content text string.
  String data = '';

  /// The last JSON record ("z") produced by completing the Account
  /// Application form. This is the only way note content is set; it is
  /// treated as the single source of truth for `_textController.text`.
  String _generatedContent = '';

  /// Guards against reacting to text changes that we ourselves triggered
  /// when writing `_generatedContent` into the controller.
  bool _applyingGeneratedContent = false;

  @override
  void initState() {
    super.initState();
    // The note content starts empty. It can only be populated by
    // completing the Account Application form below, which writes the
    // completed "z" JSON record into the controller. Direct user typing
    // into the content field is blocked (see _onContentChanged).
    _textController = StyledTextEditingController();
    _scrollController = ScrollController();
    _scaffoldController = widget.scaffoldController;

    // Start listening to changes so any edit that didn't come from
    // _setGeneratedContent gets reverted, and so `data` stays in sync.
    _textController!.addListener(_onContentChanged);

    // Focus node for the title text field. Title input is retained and
    // works exactly as before.
    _focusTitle = FocusNode();

    // Focus node for the note content field. `canRequestFocus: false`
    // prevents the user from ever placing the cursor in it or typing,
    // since content is now only produced via the Account Application
    // form.
    _focusContent = FocusNode(canRequestFocus: false);
  }

  @override
  void dispose() {
    _textController!.dispose(); // Dispose the StyledTextEditingController
    _scrollController.dispose(); // Dispose the ScrollController
    _focusTitle.dispose(); // Dispose the title focus node
    _focusContent.dispose(); // Dispose the content focus node
    super.dispose();
  }

  /// Reacts to changes on `_textController`. Because the content field
  /// can no longer take keyboard focus, this should only ever fire as a
  /// result of `_setGeneratedContent`; the equality check and guard flag
  /// are defence-in-depth in case something else (e.g. a programmatic
  /// paste) changes the text outside that flow, in which case the change
  /// is reverted back to the last generated "z" record.
  void _onContentChanged() {
    if (_applyingGeneratedContent) return;

    if (_textController!.text != _generatedContent) {
      _setGeneratedContent(_generatedContent);
      return;
    }

    setState(() {
      data = _textController!.text;
    });
  }

  /// Writes `json` into the note content, replacing anything currently
  /// there, and records it as the new source of truth so it can't be
  /// hand-edited afterwards.
  void _setGeneratedContent(String json) {
    _generatedContent = json;
    _applyingGeneratedContent = true;
    _textController!.text = json;
    _applyingGeneratedContent = false;
    setState(() {
      data = json;
    });
  }

  /// Parses a comma-separated string of dependant dates of birth into a
 
  String? _parseDependantDobs(String? value) {
    final formState = _appFormKey.currentState;
    final dependantsRaw = formState?.fields['dependants']?.value;
    final dependants = int.tryParse('${dependantsRaw ?? ''}') ?? 0;

    final dobList = value?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [];

    // Test length of the
    // list of dates against the number of dependants. If there are more dependants than dates, return an error message. If there are no dates but dependants > 0, return an error message. Otherwise, return the cleaned-up list of dates as a comma-separated string.

    if (value == null || value.trim().isEmpty) {
      if (dependants > 0) {
        return 'The DoB (Date of Birth) as yyyy-MM-dd is required for each dependent';
      }
      return null;
    }

    if (dobList.length != dependants) {
      return 'Number of Dates of Birth (${dobList.length}) does not match number of dependants ($dependants)';
    }

    for (String date in dobList) {
      try {
        isoDateOnlyFormat.parseStrict(date);
      } catch (e) {
        return 'Please enter $date in the valid date format yyyy-MM-dd.';
      }
    }
    value = dobList.join(', '); // Clean up the value to have consistent formatting

    return null;
  }

  /// Returns the cleaned-up (trimmed, consistently comma-space-joined)
  /// dependant DoB string for `customer.dob_of_dependants`, or `null` if
  /// none were entered. This is distinct from [_parseDependantDobs],
  /// which is a validator and returns `null` to mean "valid" rather than
  /// "empty" - it must not be used to derive the saved value.
  String? _cleanDependantDobs(String? value) {
    final dobList = value
            ?.split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    if (dobList.isEmpty) return null;
    return dobList.join(', ');
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is a required field and cannot be left blank';
    }
    return null;
  }

  final _emailValidator = FormBuilderValidators.compose<String>([
    FormBuilderValidators.required(),
    FormBuilderValidators.email(),
  ]);

  /// Required + valid mobile phone number, for
  /// `customer.mobile_phone_number`.

  final _phoneValidator = FormBuilderValidators.compose<String>([
    FormBuilderValidators.required(),
    FormBuilderValidators.phoneNumber(),
  ]);

  /// Required + valid URL, per "y"'s `format: "uri"` fields (`user.provider`,
  /// `customer.face_image.url`).

  final _urlValidator = FormBuilderValidators.compose<String>([
    FormBuilderValidators.required(),
    FormBuilderValidators.url(),
  ]);

  /// `customer.bank_id` must be in the form nn-nn-nn (two digits, dash, two
  /// digits, dash, two digits).

  static final RegExp _bankIdPattern = RegExp(r'^\d{2}-\d{2}-\d{2}$');

  String? _bankIdValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    if (!_bankIdPattern.hasMatch(value!)) {
      return 'Bank Identification code must be in the form nn-nn-nn (BSB), e.g. 12-34-56';
    }
    return null;
  }

  /// Formats a picked [DateTime] as a date-only ISO 8601 string
  /// (`yyyy-MM-dd`) for "z" - "y" dates never need a time component.

  String? _dateOnlyIso(dynamic value) {
    if (value is DateTime) {
      return isoDateOnlyFormat.format(value);
    }
    return null;
  }

  /// Whether the note has unsaved changes worth enabling Save for. Since
  /// [NewNote] always creates a brand new note, this mirrors the
  /// "not existing" branch of `NoteEditScrollView`'s own `_hasChanges`:
  /// enabled once a title or some content has been entered.

  bool get _hasChanges {
    final title =
        (formKey.currentState?.fields[noteTitlePred]?.value as String?) ??
            widget.initialTitle ??
            '';
    return title.trim().isNotEmpty || data.trim().isNotEmpty;
  }

  /// Opens the structured data-entry form for the Account Application
  /// record described by "y" (the Proto PI JSON schema).

  Future<void> _showApplicationForm(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: FormBuilder(
                key: _appFormKey,
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      'Account Application (against Proto PI JSON schema)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    // Top-level application fields.

                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'account_application_id',
                      decoration: const InputDecoration(
                        labelText: 'Account Application ID (UUID)',
                      ),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'product_code',
                      decoration:
                          const InputDecoration(labelText: 'Product Code'),
                      validator: _requiredValidator,
                    ),

                    const SizedBox(height: 16),
                    Text('User', style: Theme.of(context).textTheme.titleMedium),
                    const Divider(),

                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'user_id',
                      decoration:
                          const InputDecoration(labelText: 'User ID (UUID)'),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'user_email',
                      decoration: const InputDecoration(labelText: 'User Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'provider_id',
                      decoration:
                          const InputDecoration(labelText: 'Provider ID'),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'provider',
                      decoration: const InputDecoration(
                          labelText: 'Provider (URL)',),
                      keyboardType: TextInputType.url,
                      validator: _urlValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'username',
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: _requiredValidator,
                    ),

                    const SizedBox(height: 16),
                    Text('Customer',
                        style: Theme.of(context).textTheme.titleMedium,),
                    const Divider(),

                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'bank_id',
                      decoration: const InputDecoration(
                        labelText: 'Bank ID',
                        hintText: 'nn-nn-nn',
                      ),
                      validator: _bankIdValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'customer_id',
                      decoration: const InputDecoration(
                          labelText: 'Customer ID (UUID)',),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'customer_number',
                      decoration:
                          const InputDecoration(labelText: 'Customer Number'),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'legal_name',
                      decoration:
                          const InputDecoration(labelText: 'Legal Name'),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'mobile_phone_number',
                      decoration: const InputDecoration(
                          labelText: 'Mobile Phone Number',),
                      keyboardType: TextInputType.phone,
                      validator: _phoneValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'customer_email',
                      decoration:
                          const InputDecoration(labelText: 'Customer Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),

                    const SizedBox(height: 12),
                    Text('Face Image',
                        style: Theme.of(context).textTheme.titleSmall,),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'face_image_url',
                      decoration:
                          const InputDecoration(labelText: 'Face Image URL'),
                      keyboardType: TextInputType.url,
                      validator: _urlValidator,
                    ),
                    FormBuilderDateTimePicker(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'face_image_date',
                      inputType: InputType.date,
                      format: auDateFormat,
                      decoration:
                          const InputDecoration(labelText: 'Face Image Date'),
                      validator: (v) =>
                          v == null ? 'This field is required' : null,
                    ),

                    const SizedBox(height: 12),
                    FormBuilderDateTimePicker(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'date_of_birth',
                      inputType: InputType.date,
                      format: auDateFormat,
                      decoration:
                          const InputDecoration(labelText: 'Date of Birth'),
                      validator: (v) =>
                          v == null ? 'This field is required' : null,
                    ),
                    FormBuilderDropdown<String>(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'relationship_status',
                      decoration: const InputDecoration(
                          labelText: 'Relationship Status',),
                      items: relationshipStatusOptions
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)),)
                          .toList(),
                      validator: (v) =>
                          v == null ? 'This field is required' : null,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'dependants',
                      decoration:
                          const InputDecoration(labelText: 'Dependants'),
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'dob_of_dependants',
                      decoration: const InputDecoration(
                        labelText: 'Dates of Birth of Dependants',
                        helperText:
                            'Comma-separated dates, e.g. 2015-04-01, 2018-09-12',
                      ),
                      validator: _parseDependantDobs,
                    ),

                    const SizedBox(height: 12),
                    Text('Credit Rating',
                        style: Theme.of(context).textTheme.titleSmall,),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'credit_rating_rating',
                      decoration: const InputDecoration(labelText: 'Rating'),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'credit_rating_source',
                      decoration: const InputDecoration(labelText: 'Source'),
                      validator: _requiredValidator,
                    ),

                    const SizedBox(height: 12),
                    Text('Credit Limit',
                        style: Theme.of(context).textTheme.titleSmall,),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'credit_limit_currency',
                      decoration: const InputDecoration(
                        labelText: 'Currency (As per ISO 4217, e.g. "GBP")',
                      ),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'credit_limit_amount',
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),

                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'highest_education_attained',
                      decoration: const InputDecoration(
                          labelText: 'Highest Education Attained',),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'employment_status',
                      decoration: const InputDecoration(
                          labelText: 'Employment Status',),
                      validator: _requiredValidator,
                    ),
                    FormBuilderSwitch(
                      name: 'kyc_status',
                      title: const Text('KYC Status (passed)'),
                      initialValue: false,
                    ),
                    FormBuilderDateTimePicker(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'last_ok_date',
                      inputType: InputType.date,
                      format: auDateFormat,
                      decoration:
                          const InputDecoration(labelText: 'Last OK Date'),
                      validator: (v) =>
                          v == null ? 'This field is required' : null,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'title',
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'branch_id',
                      decoration:
                          const InputDecoration(labelText: 'Branch ID'),
                      validator: _requiredValidator,
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      name: 'Name_suffix',
                      decoration: const InputDecoration(
                        labelText: 'Name Suffix',
                        helperText: 'Optional',
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _completeApplicationEntry,
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Called when the user has completed entering the Account Application
  /// data ("y"). Validates the form, assembles the entered values into a
  /// single JSON record that matches the shape of "y" (referred to as
  /// "z"), and replaces the note's content with "z".

  void _completeApplicationEntry() {
    final formState = _appFormKey.currentState;
    if (formState == null || !formState.saveAndValidate()) {
      return;
    }

    final v = formState.value;

    final Map<String, dynamic> z = {
      'account_application_id': v['account_application_id'],
      'product_code': v['product_code'],
      'user': {
        'user_id': v['user_id'],
        'email': v['user_email'],
        'provider_id': v['provider_id'],
        'provider': v['provider'],
        'username': v['username'],
      },
      'customer': {
        'bank_id': v['bank_id'],
        'customer_id': v['customer_id'],
        'customer_number': v['customer_number'],
        'legal_name': v['legal_name'],
        'mobile_phone_number': v['mobile_phone_number'],
        'email': v['customer_email'],
        'face_image': {
          'url': v['face_image_url'],
          'date': _dateOnlyIso(v['face_image_date']),
        },
        'date_of_birth': _dateOnlyIso(v['date_of_birth']),
        'relationship_status': v['relationship_status'],
        'dependants': int.tryParse('${v['dependants']}') ?? 0,
        'dob_of_dependants': _cleanDependantDobs(v['dob_of_dependants']),
        'credit_rating': {
          'rating': v['credit_rating_rating'],
          'source': v['credit_rating_source'],
        },
        'credit_limit': {
          'currency': v['credit_limit_currency'],
          'amount': v['credit_limit_amount'],
        },
        'highest_education_attained': v['highest_education_attained'],
        'employment_status': v['employment_status'],
        'kyc_status': v['kyc_status'] ?? false,
        'last_ok_date': _dateOnlyIso(v['last_ok_date']),
        'title': v['title'],
        'branch_id': v['branch_id'],
        'name_suffix': v['name_suffix'],
      },
    };

    final encoder = const JsonEncoder.withIndent('  ');
    final zJson = encoder.convert(z);

    // Replace whatever content is currently in the note with the
    // completed "z" JSON record. This is the only way note content is
    // ever set - there is no free-text entry for it any more.

    _setGeneratedContent(zJson);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NoteEditScrollView(
          formKey: formKey,
          textController: _textController,
          scaffoldController: _scaffoldController,
          focusTitle: _focusTitle,
          focusContent: _focusContent,
          noteTitle: widget.initialTitle,
          childPage: ListMyNotesScreen(
            scaffoldController: _scaffoldController,
          ),
          data: data,
          showContentEditor: false,
          showSaveButton: false,
          onFormChanged: () => setState(() {}),
        ),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'enterApplicationData',
                onPressed: () => _showApplicationForm(context),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('Enter Application Data'),
              ),
              const SizedBox(width: 12),
              NoteSaveButton(
                textController: _textController!,
                formKey: formKey,
                scaffoldController: _scaffoldController,
                enabled: _hasChanges,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
