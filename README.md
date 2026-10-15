# Syntax Tree Preserve Alignment

Preserves existing alignment of two or more consecutive simple assignments
or block declarations. It does not align previously unaligned code.

```ruby
a      = [1, 2]
longer = [3, 4]

let(:invitation_repository)  { invitation_repository }
let(:restriction_repository) { restriction_repository }
let!(:outbox_events)         { outbox_events }
```

## Install

Use the Ruby environment that provides your `stree` executable:

```sh
gem build syntax_tree-preserve_alignment.gemspec
gem install ./syntax_tree-preserve_alignment-0.2.0.gem
stree write --plugins=plugin/preserve_alignment example.rb
```

Alternatively add `--plugins=plugin/preserve_alignment` to your project's
`.streerc`. It can coexist with `plugin/single_quotes`.

## Rules

- At least two sibling assignments must already have their equals signs at the
  same column and share an indentation level.
- Blank lines, standalone comments, other statements, different columns and
  ignored statements end a series.
- Local, instance, class and global variables, and simple constants are supported.
- Multiline values and trailing comments are supported. Values still undergo
  ordinary Syntax Tree formatting, including line wrapping.
- Names of equal length need no extra padding to qualify.
- Multiple assignments, setters, constant paths, operator assignments,
  non-ASCII targets and lines containing tabs are left to the standard formatter.
- Existing spacing is preserved relative to the normalized indentation.

## Block declarations

- At least two consecutive declarations must already have their opening `{` or
  `do` at the same column and share an indentation level.
- Different methods may share a group: `let`, `let!`, `subject`, or another DSL.
- Supported prefixes are receiverless calls with one simple, unquoted symbol
  argument in parentheses, such as `let!(:events)`. Prefixes must be ASCII,
  on one line, without comments or tabs.
- Blank lines, standalone comments, other instructions, ignored statements and
  changes in indentation or opening column end a group.
- Bodies can be multiline. Syntax Tree still formats them and chooses braces
  or `do/end`. Trailing comments are preserved.
- Prefix spacing is normalized, while the opening column stays relative to the
  normalized indentation. Recognized prefixes stay on one line even when an
  exceptionally long name exceeds the configured print width.
- Calls with receivers, dynamic or multiple arguments, quoted symbols and
  multiline prefixes are formatted normally without preserving padding.

## Internals

`Assignments` and `Blocks` are independent module families in separate files.
Each inspects `Statements#format` and stores its own context on the formatter,
restoring it after nested statement lists. They never mix candidates.

Assignments customize `Assign#format`. Blocks customize
`MethodAddBlock#format_contents` and the block opening formatters, leaving body
formatting to Syntax Tree. Padding is emitted before PrettierPrint calculates
line breaks. State belongs to each formatter, not to the AST or a global variable.

Compatibility is pinned to Syntax Tree 6.3.0 because assignment formatting
mirrors its internal grouping and indentation. Check those internals and run
the tests before upgrading.

## Test

```sh
bundle install
bundle exec rspec
```
