# Syntax Tree Preserve Alignment

Preserves existing alignment of two or more consecutive simple assignments.
It does not align previously unaligned code or method blocks.

```ruby
a      = [1, 2]
longer = [3, 4]
```

## Install

Use the Ruby environment that provides your `stree` executable:

```sh
gem build syntax_tree-preserve_alignment.gemspec
gem install ./syntax_tree-preserve_alignment-0.1.0.gem
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

The plugin customizes `Statements#format` to identify groups, and
`Assign#format` to emit their padding before PrettierPrint calculates line
breaks. State belongs to each formatter, not to the AST or a global variable.

Compatibility is pinned to Syntax Tree 6.3.0 because assignment formatting
mirrors its internal grouping and indentation. Check those internals and run
the tests before upgrading.

## Test

```sh
bundle install
bundle exec rspec
```
