# Limits and Errors

Explicit ceilings that fail instead of degrading, and errors you can act on.

## Limits

``CSVLimits`` bounds every call:

| Limit | Default | Error |
|---|---|---|
| ``CSVLimits/maxInputBytes`` | 8 MiB | ``CSVError/Code-swift.enum/inputTooLarge`` |
| ``CSVLimits/maxRecords`` | 1,000,000 | ``CSVError/Code-swift.enum/tooManyRecords`` |
| ``CSVLimits/maxFieldsPerRecord`` | 1,024 | ``CSVError/Code-swift.enum/tooManyFields`` |
| ``CSVLimits/maxFieldBytes`` | 1 MiB | ``CSVError/Code-swift.enum/fieldTooLarge`` |

The input size includes a byte order mark. The record limit counts data records, not the
header. The field limit applies to the header too. Field size is measured in UTF-8 bytes
after `""` unescaping. A result is never truncated: the call either returns the complete
table or throws.

## Cancellation

The parser checks `Task.isCancelled` on entry and every 1,024 records. It throws
``CSVError/Code-swift.enum/cancelled`` when the surrounding task is cancelled.

## Errors

``CSVError`` carries a ``CSVError/code-swift.property``, a ``CSVError/message``, and a
1-based ``CSVError/line`` and ``CSVError/column``. Columns count Unicode scalars.
Messages never contain file paths, so callers add their own context. Use
``CSVError/shifted(byLines:)`` when the CSV is embedded in a larger file.

| Code | Position |
|---|---|
| ``CSVError/Code-swift.enum/invalidEncoding`` | the first byte of the bad sequence |
| ``CSVError/Code-swift.enum/quoteInUnquotedField`` | the quote |
| ``CSVError/Code-swift.enum/unterminatedQuotedField`` | the opening quote |
| ``CSVError/Code-swift.enum/unexpectedCharacterAfterQuote`` | the character after the closing quote |
| ``CSVError/Code-swift.enum/bareCarriageReturn`` | the carriage return |
| ``CSVError/Code-swift.enum/missingHeader`` | line 1, column 1 |
| ``CSVError/Code-swift.enum/emptyHeaderName``, ``CSVError/Code-swift.enum/duplicateHeaderName`` | the start of the name |
| ``CSVError/Code-swift.enum/fieldCountMismatch`` | the first extra field, the end of a short record, or the start of a blank line |
| ``CSVError/Code-swift.enum/inputTooLarge`` | line 1, column 1 |
| ``CSVError/Code-swift.enum/tooManyRecords`` | the start of the first record over the limit |
| ``CSVError/Code-swift.enum/tooManyFields``, ``CSVError/Code-swift.enum/fieldTooLarge`` | the start of the field |
| ``CSVError/Code-swift.enum/jsonLimitExceeded`` | the record's line, column 1 |

New codes may be added in minor releases, so `switch` over ``CSVError/Code-swift.enum``
with a `default` case.
