require "rspec"
require "syntax_tree"
require_relative "../../lib/syntax_tree/plugin/preserve_alignment"

module SyntaxTree
  module PreserveAlignment
    RSpec.describe Assignments do
      it "preserves logical-or assignment alignment while formatting and wrapping values" do
        source = "a      ||= [111111,222222]\nlonger ||= [333333,444444]\n"

        result = SyntaxTree.format(source, 20)

        expect(result).to eq(<<~'RUBY')
          a      ||= [
            111_111,
            222_222
          ]
          longer ||= [
            333_333,
            444_444
          ]
        RUBY
        expect(SyntaxTree.format(result, 20)).to eq(result)
      end

      it "preserves indexed logical-or assignments while normalizing targets" do
        source = <<~'RUBY'
          def example
              injector[ :config ]    ||= [1,2]
              injector[:db]          ||= [3,4]
          end
        RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
          def example
            injector[:config]      ||= [1, 2]
            injector[:db]          ||= [3, 4]
          end
        RUBY
        expect(SyntaxTree.format(result)).to eq(result)
      end

      it "preserves indexed plain assignments" do
        source = "items[:a]    = 1\nitems[:long] = 2\n"

        expect(SyntaxTree.format(source)).to eq(source)
      end

      it "normalizes a lone indexed assignment" do
        expect(SyntaxTree.format("items[:a]    ||= 1\n")).to eq(
          "items[:a] ||= 1\n"
        )
      end

      it "excludes multiline indexed targets" do
        source = "items[\n  :a\n]    ||= 1\nitems[:long] ||= 2\n"

        expect(SyntaxTree.format(source)).to eq(
          "items[:a] ||= 1\nitems[:long] ||= 2\n"
        )
      end

      it "normalizes a lone logical-or assignment" do
        expect(SyntaxTree.format("a    ||= 1\n")).to eq("a ||= 1\n")
      end

      it "does not align previously unaligned logical-or assignments" do
        source = "a ||= 1\nlonger ||= 2\n"

        expect(SyntaxTree.format(source)).to eq(source)
      end

      it "separates series when assignment operators change" do
        source = "a    = 1\nb    ||= 2\nc    = 3\nd    ||= 4\n"

        expect(SyntaxTree.format(source)).to eq(
          "a = 1\nb ||= 2\nc = 3\nd ||= 4\n"
        )
      end

      it "excludes logical-or setter assignments" do
        source = "obj.a    ||= 1\nobj.b    ||= 2\n"

        expect(SyntaxTree.format(source)).to eq("obj.a ||= 1\nobj.b ||= 2\n")
      end

      it "excludes logical-and assignments" do
        source = "a    &&= 1\nb    &&= 2\n"

        expect(SyntaxTree.format(source)).to eq("a &&= 1\nb &&= 2\n")
      end

      it "ends logical-or series at standalone comments" do
        source = "a    ||= 1\n# boundary\nb    ||= 2\n"

        expect(SyntaxTree.format(source)).to eq(
          "a ||= 1\n# boundary\nb ||= 2\n"
        )
      end

      it "excludes ignored logical-or assignments from series" do
        source = "# stree-ignore\na    ||= [1,2]\nb    ||= [3,4]\n"

        expect(SyntaxTree.format(source)).to eq(
          "# stree-ignore\na    ||= [1,2]\nb ||= [3, 4]\n"
        )
      end

      it "preserves nested logical-or series and trailing comments" do
        source = <<~'RUBY'
          def example
              @a    ||= [1,2] # note
              @long ||= [3,4]
              call do
                  x    ||= 1
                  name ||= 2
              end
              @@a   ||= 3
              $long ||= 4
          end
        RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
          def example
            @a    ||= [1, 2] # note
            @long ||= [3, 4]
            call do
              x    ||= 1
              name ||= 2
            end
            @@a   ||= 3
            $long ||= 4
          end
        RUBY
        expect(SyntaxTree.format(result)).to eq(result)
      end

      it "preserves logical-or series with heredoc values" do
        source = <<~'RUBY'
          a      ||= <<~TEXT
            hello
          TEXT
          longer ||= <<~TEXT
            world
          TEXT
        RUBY

        expect(SyntaxTree.format(source)).to eq(source)
      end

      it "does not preserve padding for a single assignment" do
        source = "a    = 1\n"

        result = SyntaxTree.format(source)

        expect(result).to eq("a = 1\n")
      end

      it "does not align assignments that were not aligned" do
        source = <<~'RUBY'
        a = 1
        longer = 2
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        a = 1
        longer = 2
      RUBY
      end

      it "ends a series at a blank line" do
        source = <<~'RUBY'
        a    = 1

        b    = 2
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        a = 1

        b = 2
      RUBY
      end

      it "ends a series at a standalone comment" do
        source = <<~'RUBY'
        a    = 1
        # boundary
        b    = 2
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        a = 1
        # boundary
        b = 2
      RUBY
      end

      it "ends a series at another instruction" do
        source = <<~'RUBY'
        a    = 1
        puts 0
        b    = 2
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        a = 1
        puts 0
        b = 2
      RUBY
      end

      it "does not group assignments on the same line" do
        source = "a    = 1; b = 2\n"

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        a = 1
        b = 2
      RUBY
      end

      it "does not preserve padding for operator assignments" do
        source = <<~'RUBY'
        a    += 1
        b    += 2
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        a += 1
        b += 2
      RUBY
      end

      it "does not preserve padding for multiple assignments" do
        source = <<~'RUBY'
        a, b    = 1, 2
        c, d    = 3, 4
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        a, b = 1, 2
        c, d = 3, 4
      RUBY
      end

      it "does not preserve padding for setter assignments" do
        source = <<~'RUBY'
        obj.a    = 1
        obj.b    = 2
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        obj.a = 1
        obj.b = 2
      RUBY
      end

      it "does not preserve padding for constant path assignments" do
        source = <<~'RUBY'
        A::B    = 1
        A::C    = 2
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        A::B = 1
        A::C = 2
      RUBY
      end

      it "does not group assignments with non-ASCII targets" do
        source = <<~'RUBY'
        é    = 1
        a    = 2
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        é = 1
        a = 2
      RUBY
      end

      it "does not preserve tab padding" do
        source = <<~RUBY
        a\t= 1
        b\t= 2
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        a = 1
        b = 2
      RUBY
      end

      it "leaves ignored assignments intact and excludes them from series" do
        source = <<~'RUBY'
        # stree-ignore
        a    = [1,2]
        b    = [3,4]
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY')
        # stree-ignore
        a    = [1,2]
        b = [3, 4]
      RUBY
      end

      it "preserves independent nested groups and normalizes indentation" do
        source = <<~'RUBY'
        def example
            a    = 1
            b    = 2
            call do
                @a    = 3
                @long = 4
            end
            x   = 5
            y   = 6
        end
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY'), [source, result].inspect
        def example
          a    = 1
          b    = 2
          call do
            @a    = 3
            @long = 4
          end
          x   = 5
          y   = 6
        end
      RUBY
      end

      it "preserves supported targets comments and partial series" do
        source = <<~'RUBY'
        @@a   = [1,2] # note
        $long = [3,4]
        A     = 5
        other = 6
        x = 7
        name = 8
        city = 9
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY'), [source, result].inspect
        @@a   = [1, 2] # note
        $long = [3, 4]
        A     = 5
        other = 6
        x = 7
        name = 8
        city = 9
      RUBY
      end

      it "wraps long values without losing assignment alignment" do
        source = <<~'RUBY'
        a      = [111111, 222222, 333333]
        longer = [444444, 555555, 666666]
      RUBY
        result = SyntaxTree.format(source, 20)
        expect(result).to eq(<<~'RUBY')
        a      = [
          111_111,
          222_222,
          333_333
        ]
        longer = [
          444_444,
          555_555,
          666_666
        ]
      RUBY
        expect(SyntaxTree.format(result, 20)).to eq(result)
      end

      it "preserves alignment of assignments with multiline values" do
        source = <<~'RUBY'
        a      = begin
          1
        end
        longer = begin
          2
        end
      RUBY
        result = SyntaxTree.format(source)
        expect(result).to eq(<<~'RUBY')
        a      =
          begin
            1
          end
        longer =
          begin
            2
          end
      RUBY
      end

      it "does not mistake equals signs inside strings for assignment operators" do
        source = <<~'RUBY'
        a      = "hello=world"
        longer = "value"
      RUBY
        result = SyntaxTree.format(source)
        expect(result).to eq(<<~'RUBY')
        a      = "hello=world"
        longer = "value"
      RUBY
      end

      it "preserves alignment of assignments with heredoc values" do
        source = <<~'RUBY'
        a      = <<~TEXT
          hello
        TEXT
        longer = <<~TEXT
          world
        TEXT
      RUBY
        result = SyntaxTree.format(source)
        expect(result).to eq(<<~'RUBY')
        a      = <<~TEXT
          hello
        TEXT
        longer = <<~TEXT
          world
        TEXT
      RUBY
      end

      it "preserves two aligned assignments while formatting values" do
        source = <<~'RUBY'
        a      = [1,2]
        longer = [3,4]
      RUBY

        result = SyntaxTree.format(source)

        expect(result).to eq(<<~'RUBY'), [source, result].inspect
        a      = [1, 2]
        longer = [3, 4]
      RUBY
      end
    end
  end
end
