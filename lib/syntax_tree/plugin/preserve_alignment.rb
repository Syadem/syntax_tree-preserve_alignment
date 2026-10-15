# frozen_string_literal: true

require "syntax_tree"
require_relative "preserve_alignment/assignments"
require_relative "preserve_alignment/blocks"

module SyntaxTree
  Formatter.prepend(PreserveAlignment::Assignments::FormatterContext)
  Statements.prepend(PreserveAlignment::Assignments::StatementFormatting)
  Assign.prepend(PreserveAlignment::Assignments::AssignmentFormatting)

  Formatter.prepend(PreserveAlignment::Blocks::FormatterContext)
  Statements.prepend(PreserveAlignment::Blocks::StatementFormatting)
  MethodAddBlock.prepend(PreserveAlignment::Blocks::CallFormatting)
  BlockNode.prepend(PreserveAlignment::Blocks::BlockFormatting)
end
