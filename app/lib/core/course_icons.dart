import 'package:flutter/material.dart';

/// Maps the icon key sent by the API to a Material icon.
IconData courseIcon(String key) => switch (key) {
      'widgets' => Icons.widgets_rounded,
      'code' => Icons.code_rounded,
      'public' => Icons.public_rounded,
      'merge' => Icons.merge_type_rounded,
      'api' => Icons.api_rounded,
      _ => Icons.menu_book_rounded,
    };
