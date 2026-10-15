require "rspec"
require_relative "../../lib/syntax_tree/plugin/preserve_alignment"

module SyntaxTree
  module PreserveAlignment
    RSpec.describe Blocks do
      it "preserves alignment between let and subject declarations" do
        source = <<~'RUBY'
          let(:a)     { [1,2] }
          subject(:b) { [3,4] }
        RUBY
        result = SyntaxTree.format(source)
        expect(result).to eq(<<~'RUBY')
          let(:a)     { [1, 2] }
          subject(:b) { [3, 4] }
        RUBY
      end

      it "does not preserve padding for a single block declaration" do
        source = "let(:a)     { 1 }\n"
        expect(SyntaxTree.format(source)).to eq("let(:a) { 1 }\n")
      end

      it "does not align declarations that were not aligned" do
        source = <<~'RUBY'
          let(:a) { 1 }
          let(:longer) { 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(source)
      end

      it "ends a block series at a blank line" do
        source = <<~'RUBY'
          let(:a)    { 1 }

          let(:b)    { 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          let(:a) { 1 }

          let(:b) { 2 }
        RUBY
      end

      it "ends a block series at a standalone comment" do
        source = <<~'RUBY'
          let(:a)    { 1 }
          # boundary
          let(:b)    { 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          let(:a) { 1 }
          # boundary
          let(:b) { 2 }
        RUBY
      end

      it "ends a block series at another instruction" do
        source = <<~'RUBY'
          let(:a)    { 1 }
          prepare
          let(:b)    { 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          let(:a) { 1 }
          prepare
          let(:b) { 2 }
        RUBY
      end

      it "excludes ignored declarations from block series" do
        source = <<~'RUBY'
          # stree-ignore
          let(:a)    { [1,2] }
          let(:b)    { [3,4] }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          # stree-ignore
          let(:a)    { [1,2] }
          let(:b) { [3, 4] }
        RUBY
      end

      it "preserves mixed openings with multiline bodies and trailing comments" do
        source = <<~'RUBY'
          let(:a)      { 1 } # note
          let(:longer) do
            2
            3
          end
        RUBY
        result = SyntaxTree.format(source)
        expect(result).to eq(source)
        expect(SyntaxTree.format(result)).to eq(result)
      end

      it "wraps long bodies without losing alignment on the next pass" do
        source = <<~'RUBY'
          let(:a)      { [111111, 222222, 333333, 444444, 555555, 666666, 777777, 888888, 999999, 111111, 222222, 333333, 444444, 555555] }
          let(:longer) { [1,2] }
        RUBY
        result = SyntaxTree.format(source, 120)
        expect(result).to eq(<<~'RUBY')
          let(:a)      do
            [
              111_111,
              222_222,
              333_333,
              444_444,
              555_555,
              666_666,
              777_777,
              888_888,
              999_999,
              111_111,
              222_222,
              333_333,
              444_444,
              555_555
            ]
          end
          let(:longer) { [1, 2] }
        RUBY
        expect(SyntaxTree.format(result, 120)).to eq(result)
      end

      it "keeps assignment and block contexts independent across nested lists" do
        source = <<~'RUBY'
          let(:outer)  do
              a    = [1,2]
              long = [3,4]
              let(:a)     { 1 }
              subject(:b) { 2 }
              x    = 5
              long = 6
          end
          let(:second) { 3 }
        RUBY
        result = SyntaxTree.format(source)
        expect(result).to eq(<<~'RUBY')
          let(:outer)  do
            a    = [1, 2]
            long = [3, 4]
            let(:a)     { 1 }
            subject(:b) { 2 }
            x    = 5
            long = 6
          end
          let(:second) { 3 }
        RUBY
        expect(SyntaxTree.format(result)).to eq(result)
        expect(SyntaxTree.format("let(:a)    { 1 }\n")).to eq("let(:a) { 1 }\n")
      end

      it "normalizes prefixes and preserves alignment relative to indentation" do
        source = <<~'RUBY'
          describe :example do
              let( :a )    { [1,2] }
              subject(:b)  { [3,4] }
          end
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          describe :example do
            let(:a)      { [1, 2] }
            subject(:b)  { [3, 4] }
          end
        RUBY
      end

      it "does not extend an aligned series to an unaligned neighbor" do
        source = <<~'RUBY'
          let(:a)     { 1 }
          subject(:b) { 2 }
          let(:c)  { 3 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          let(:a)     { 1 }
          subject(:b) { 2 }
          let(:c) { 3 }
        RUBY
      end

      it "does not preserve padding for declarations with receivers" do
        source = <<~'RUBY'
          obj.let(:a)    { 1 }
          obj.let(:b)    { 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          obj.let(:a) { 1 }
          obj.let(:b) { 2 }
        RUBY
      end

      it "does not preserve padding for dynamic arguments" do
        source = <<~'RUBY'
          let(name)    { 1 }
          let(other)   { 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          let(name) { 1 }
          let(other) { 2 }
        RUBY
      end

      it "does not preserve padding for multiple arguments" do
        source = <<~'RUBY'
          declare(:a, :b)    { 1 }
          declare(:c, :d)    { 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          declare(:a, :b) { 1 }
          declare(:c, :d) { 2 }
        RUBY
      end

      it "does not preserve padding for non-ASCII prefixes" do
        source = <<~'RUBY'
          let(:é)    { 1 }
          let(:a)    { 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          let(:é) { 1 }
          let(:a) { 2 }
        RUBY
      end

      it "does not preserve tab padding in block declarations" do
        source = <<~RUBY
          let(:a)\t{ 1 }
          let(:b)\t{ 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          let(:a) { 1 }
          let(:b) { 2 }
        RUBY
      end

      it "does not preserve alignment for multiline prefixes" do
        source = <<~'RUBY'
          let(
            :a
          )    { 1 }
          let(
            :b
          )    { 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          let(:a) { 1 }
          let(:b) { 2 }
        RUBY
      end

      it "does not preserve padding for calls without parentheses" do
        source = <<~'RUBY'
          let :a    do
            1
          end
          let :b    do
            2
          end
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          let :a do
            1
          end
          let :b do
            2
          end
        RUBY
      end

      it "does not preserve padding for quoted symbols" do
        source = <<~'RUBY'
          let(:"a-b")    { 1 }
          let(:"c-d")    { 2 }
        RUBY
        expect(SyntaxTree.format(source)).to eq(<<~'RUBY')
          let(:"a-b") { 1 }
          let(:"c-d") { 2 }
        RUBY
      end

      it "keeps recognized prefixes on one line even beyond the print width" do
        source = <<~'RUBY'
          let(:a_very_long_symbol_name) { 1 }
          let(:b)                       { 2 }
        RUBY
        result = SyntaxTree.format(source, 20)
        expect(result).to eq(<<~'RUBY')
          let(:a_very_long_symbol_name) do
            1
          end
          let(:b)                       do
            2
          end
        RUBY
        expect(SyntaxTree.format(result, 20)).to eq(result)
      end

      it "preserves aligned declarations with different method names" do
        source = <<~'RUBY'
          let(:invitation_repository)  { [1,2] }
          let(:restriction_repository) { [3,4] }
          let!(:outbox_events)         { [5,6] }
        RUBY
        result = SyntaxTree.format(source)
        expect(result).to eq(<<~'RUBY')
          let(:invitation_repository)  { [1, 2] }
          let(:restriction_repository) { [3, 4] }
          let!(:outbox_events)         { [5, 6] }
        RUBY
        expect(SyntaxTree.format(result)).to eq(result)
      end
    end
  end
end
