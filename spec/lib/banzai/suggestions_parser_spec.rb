# frozen_string_literal: true

require 'spec_helper'

describe Banzai::SuggestionsParser do
  describe '.parse' do
    it 'returns a list of suggestion contents' do
      markdown = <<-MARKDOWN.strip_heredoc
        ```suggestion
          foo
          bar
        ```

        ```
          nothing
        ```

        ```suggestion
          xpto
          baz
        ```

        ```thing
          this is not a suggestion, it's a thing
        ```
      MARKDOWN

      expect(described_class.parse(markdown)).to eq(["  foo\n  bar",
                                                     "  xpto\n  baz"])
    end
  end
end
