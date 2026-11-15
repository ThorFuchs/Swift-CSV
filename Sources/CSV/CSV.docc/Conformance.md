# Conformance

What is tested against RFC 4180 and a published corpus, and where Swift-CSV deviates on
purpose.

## RFC 4180

Every rule of RFC 4180 section 2 has a test built from the RFC's own examples: CRLF
records, the optional final line break, the header line, spaces as content, quoted fields,
quoted line breaks, commas and quotes, and `""` escapes.

## csv-spectrum

The tests vendor [csv-spectrum](https://github.com/max-mapper/csv-spectrum) 2.0.0
(BSD-2-Clause) unmodified and run every case on every platform. Each CSV is converted with
`emptyCell: .emptyString` and compared to its JSON.

- 11 of 12 cases match exactly: `comma_in_quotes`, `empty`, `empty_crlf`,
  `escaped_quotes`, `json`, `newlines`, `newlines_crlf`, `quotes_and_newlines`, `simple`,
  `simple_crlf`, `utf8`.
- `location_coordinates` is rejected on purpose with `quoteInUnquotedField`: it has bare
  `"` characters in unquoted fields, which RFC 4180 does not allow.

## Deliberate deviations

Accepted beyond the RFC: any valid UTF-8 text, LF line breaks (also mixed with CRLF), the
`;`, tab and `|` delimiters chosen explicitly, and a leading UTF-8 byte order mark.

Required beyond the RFC: a header by default, with non-empty, unique names.

Rejected although lenient parsers accept it: quotes inside unquoted fields, text or spaces
after a closing quote, lone carriage returns, and records with a different number of
fields, including blank lines in multi-column files.
