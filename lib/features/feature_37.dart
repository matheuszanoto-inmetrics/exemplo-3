int safeParseInt(String s, {int fallback = 0}) => int.tryParse(s) ?? fallback;
