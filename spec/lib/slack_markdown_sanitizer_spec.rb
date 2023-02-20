# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SlackMarkdownSanitizer, feature_category: :integrations do
  describe '.sanitize' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :output) do
      nil                              | nil
      ''                               | ''
      '[label](url)'                   | 'label(url)'
      '<url|label>'                    | 'urllabel'
      '<a href="url">label</a>'        | 'a href="url"label/a'
    end

    with_them do
      it 'returns the expected output' do
        expect(described_class.sanitize(input)).to eq(output)
      end
    end
  end
end
