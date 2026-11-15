# Parsing Rules

How bytes become records and fields.

## Overview

Swift-CSV follows RFC 4180 with a few explicit extensions, and rejects everything the RFC
does not allow instead of guessing what was meant.

## Records and line breaks

- A record ends with LF or CRLF. Both may appear in one file.
- The last record may end with or without a line break. A final line break does not add
  a record.
- An empty line is a record with one empty field. With a multi-column header that is a
  ``CSVError/Code-swift.enum/fieldCountMismatch``; the message says the line is blank.
- A carriage return outside quotes must be followed by a line feed, otherwise the parse
  fails with ``CSVError/Code-swift.enum/bareCarriageReturn``.
- A UTF-8 byte order mark at the very start is skipped. Any other is text.

## Fields

- Fields are separated by the ``CSVOptions/delimiter``: ``CSVDelimiter/comma`` by default,
  or ``CSVDelimiter/semicolon``, ``CSVDelimiter/tab`` or ``CSVDelimiter/pipe``. The
  delimiter is never detected.
- A field that starts with `"` is quoted. It ends at the next `"` that is not doubled. It
  may contain delimiters, line breaks and `""`, which stands for one quote.
- Line breaks inside quotes are kept byte for byte, `\n` or `\r\n`.
- After a closing quote only a delimiter, a line break or the end of the input may follow,
  otherwise ``CSVError/Code-swift.enum/unexpectedCharacterAfterQuote``.
- A field that does not start with `"` must not contain one, otherwise
  ``CSVError/Code-swift.enum/quoteInUnquotedField``. This includes a space before an
  opening quote, as in `a, "b"`.
- Spaces are part of the field and are never trimmed.

## Values

Every value is a UTF-8 `String`, exactly as written after `""` unescaping. `007`, `1.50`,
`true`, `null` and `2026-11-15` are strings. `""` and an empty unquoted field are both the
empty string. Converting cells to other types is the caller's job.

The input must be valid UTF-8; anything else, including UTF-16, fails with
``CSVError/Code-swift.enum/invalidEncoding``.

## Header

With ``CSVHeaderMode/required`` (the default) the first record is the header:

- An input with no records fails with ``CSVError/Code-swift.enum/missingHeader``.
- An empty name fails with ``CSVError/Code-swift.enum/emptyHeaderName``.
- A repeated name fails with ``CSVError/Code-swift.enum/duplicateHeaderName``. Names are
  compared as Swift strings, so canonically equivalent spellings (`é` and `e` + U+0301)
  are duplicates too.
- Every data record must have exactly as many fields as the header. Records are never
  padded or cut.

With ``CSVHeaderMode/absent`` every record is data, ``CSVTable/header`` is `nil`, and every
record must have as many fields as the first one.

## Line numbers

Lines are counted by line feeds, starting at 1. ``CSVRecord/line`` is the line where a
record starts, so a quoted field spanning three lines moves the next record down by three.
Error columns count Unicode scalars from the start of the line.
