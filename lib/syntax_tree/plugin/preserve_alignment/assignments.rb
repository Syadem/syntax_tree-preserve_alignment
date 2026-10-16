# frozen_string_literal: true

require "syntax_tree"

module SyntaxTree
  module PreserveAlignment
    module Assignments
      module FormatterContext
        attr_accessor :preserve_alignment_padding
      end

      module StatementFormatting
        def format(q)
          previous_padding = q.preserve_alignment_padding
          padding = {}
          series = []
          previous_end_line = nil
          # Reused for each sibling: splitting inside the loop would be quadratic.
          lines = q.source.lines

          body.each do |statement|
            candidate = nil
            if (
                 statement.is_a?(Assign) ||
                   (
                     statement.is_a?(OpAssign) &&
                       statement.operator.value == "||="
                   )
               ) && statement.target.is_a?(VarField) &&
                 statement.comments.none?(&:leading?) &&
                 statement.target.comments.empty?
              target =
                q.source[
                  statement.target.start_char...statement.target.end_char
                ]
              line = lines[statement.location.start_line - 1]
              indentation = line[/\A */].length
              tokens =
                Ripper
                  .lex(
                    q.source[
                      statement.target.end_char...statement.value.start_char
                    ]
                  )
                  .reject do |token|
                    %i[on_sp on_nl on_ignored_nl].include?(token[1])
                  end

              if target.ascii_only? && !line.include?("\t") &&
                   statement.location.start_column == indentation &&
                   tokens.length == 1 &&
                   tokens.first[1..2] ==
                     [:on_op, statement.is_a?(Assign) ? "=" : "||="] &&
                   tokens.first[0][0] == 1
                column =
                  statement.target.location.end_column + tokens.first[0][1]
                candidate = [
                  statement,
                  column,
                  indentation,
                  column - indentation - target.length,
                  tokens.first[2]
                ]
              end
            end

            unless candidate && series.any? &&
                     statement.location.start_line == previous_end_line + 1 &&
                     candidate[1..2] == series.last[1..2] &&
                     candidate[4] == series.last[4]
              series.each do |entry|
                padding[entry[0]] = entry[3]
              end if series.length >= 2
              series = []
            end

            series << candidate if candidate
            previous_end_line = statement.location.end_line
          end
          series.each do |entry|
            padding[entry[0]] = entry[3]
          end if series.length >= 2
          q.preserve_alignment_padding = padding

          super
        ensure
          q.preserve_alignment_padding = previous_padding
        end
      end

      module AssignmentFormatting
        def format(q)
          spaces = q.preserve_alignment_padding&.[](self)
          return super unless spaces && spaces >= 1

          # Keep Syntax Tree 6.3.0's grouping and value indentation unchanged.
          q.group do
            q.format(target)
            q.text(" " * spaces)
            is_a?(OpAssign) ? q.format(operator) : q.text("=")

            if skip_indent?
              q.text(" ")
              q.format(value)
            else
              q.indent do
                q.breakable_space
                q.format(value)
              end
            end
          end
        end
      end
    end
  end
end
