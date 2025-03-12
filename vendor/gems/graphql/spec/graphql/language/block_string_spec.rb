# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::BlockString do
  describe "trimming whitespace" do
    def trim_whitespace(str)
      GraphQL::Language::BlockString.trim_whitespace(str)
    end

    it "matches the examples in graphql-js" do
      # these are taken from:
      # https://github.com/graphql/graphql-js/blob/36ec0e9d34666362ff0e2b2b18edeb98e3c9abee/src/language/__tests__/blockStringValue-test.js#L12
      # A set of [before, after] pairs:
      examples = [
        [
          # Removes common whitespace:
          "
          Hello,
            World!

          Yours,
            GraphQL.
          ",
          "Hello,\n  World!\n\nYours,\n  GraphQL."
        ],
        [
          # Removes leading and trailing newlines:
          "

          Hello,
            World!

          Yours,
            GraphQL.

          ",
          "Hello,\n  World!\n\nYours,\n  GraphQL."
        ],
        [
          # Removes blank lines (with whitespace _and_ newlines:)
          "\n    \n
          Hello,
            World!

          Yours,
            GraphQL.

          \n     \n",
          "Hello,\n  World!\n\nYours,\n  GraphQL."
        ],
        [
          # Retains indentation from the first line
          "    Hello,\n      World!\n\n    Yours,\n      GraphQL.",
          "    Hello,\n  World!\n\nYours,\n  GraphQL.",
        ],
        [
          # Doesn't alter trailing spaces
          "\n    \n    Hello,     \n      World!   \n\n    Yours,     \n      GraphQL.  ",
          "Hello,     \n  World!   \n\nYours,     \n  GraphQL.  ",

        ],
        [
          # Doesn't crash when the string is only a newline
          "\n",
          ""
        ],
        [
          # Removes long blank lines
          "  \n                                     \n
          Hello,
            World!

          Yours,
            GraphQL.

          \n                                        \n",
          "Hello,\n  World!\n\nYours,\n  GraphQL."
        ]
      ]

      examples.each_with_index do |(before, after), idx|
        transformed_str = trim_whitespace(before)
        assert_equal(after, transformed_str, "Example ##{idx + 1}")
      end
    end
  end
end
