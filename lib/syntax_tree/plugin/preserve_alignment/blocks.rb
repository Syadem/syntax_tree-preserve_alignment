# frozen_string_literal: true

require "syntax_tree"

module SyntaxTree
  module PreserveAlignment
    module Blocks
      module FormatterContext
        attr_accessor :preserve_block_alignment
      end

      module StatementFormatting
        def format(q)
          previous_alignment = q.preserve_block_alignment
          alignment = {}
          series = []
          previous_end_line = nil
          lines = q.source.lines

          body.each do |statement|
            candidate = nil
            if statement.is_a?(MethodAddBlock) &&
                 statement.call.is_a?(CallNode) &&
                 statement.call.receiver.nil? &&
                 statement.comments.none?(&:leading?)
              line = lines[statement.location.start_line - 1]
              indentation = line[/\A */].length
              prefix =
                q.source[
                  statement.call.start_char...statement.block.opening.start_char
                ]
              match =
                /\A([A-Za-z_]\w*[!?]?) *\( *:([A-Za-z_]\w*) *\) +\z/.match(
                  prefix
                )

              if match && prefix.ascii_only? && !line.include?("\t") &&
                   statement.location.start_column == indentation &&
                   statement.block.opening.location.start_line ==
                     statement.location.start_line
                candidate = [
                  statement.block,
                  statement.block.opening.location.start_column,
                  indentation,
                  "#{match[1]}(:#{match[2]})"
                ]
              end
            end

            unless candidate && series.any? &&
                     statement.location.start_line == previous_end_line + 1 &&
                     candidate[1..2] == series.last[1..2]
              record_series(series, alignment)
              series = []
            end
            series << candidate if candidate
            previous_end_line = statement.location.end_line
          end
          record_series(series, alignment)
          q.preserve_block_alignment = alignment

          super
        ensure
          q.preserve_block_alignment = previous_alignment
        end

        private

        def record_series(series, alignment)
          return if series.length < 2

          column = [
            series.first[1] - series.first[2],
            series.map { |entry| entry[3].length + 1 }.max
          ].max
          series.each do |entry|
            alignment[entry[0]] = [entry[3], column - entry[3].length]
          end
        end
      end

      module CallFormatting
        def format_contents(q)
          if (entry = q.preserve_block_alignment&.[](block))
            q.text(entry[0])
            q.format(block)
          else
            super
          end
        end
      end

      module BlockFormatting
        private

        def format_flat(q, opening, closing)
          format_alignment_padding(q)
          super
        end

        def format_break(q, opening, closing)
          format_alignment_padding(q)
          super
        end

        def format_alignment_padding(q)
          if (entry = q.preserve_block_alignment&.[](self))
            q.text(" " * (entry[1] - 1))
          end
        end
      end
    end
  end
end
