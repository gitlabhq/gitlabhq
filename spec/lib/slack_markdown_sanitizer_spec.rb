# frozen_string_literal: true

require 'fast_spec_helper'

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

  describe '.sanitize_slack_link' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :output) do
      ''                               | ''
      '[label](url)'                   | '[label](url)'
      '<url|label>'                    | '&lt;url|label&gt;'
      '<url|label|more>'               | '&lt;url|label|more&gt;'
      '<a href="url">label</a>'        | '<a href="url">label</a>'
    end

    with_them do
      it 'returns the expected output' do
        expect(described_class.sanitize_slack_link(input)).to eq(output)
      end
    end
  end

  describe '.escape' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :output) do
      nil                              | nil
      ''                               | ''
      '[label](url)'                   | '[label](url)'
      '<url|label>'                    | '&lt;url|label&gt;'
      '<a href="url">label</a>'        | '&lt;a href="url"&gt;label&lt;/a&gt;'
      'a & <b> c'                      | 'a &amp; &lt;b&gt; c'
      '&lt;already escaped&gt;'        | '&amp;lt;already escaped&amp;gt;'
    end

    with_them do
      it 'escapes ampersands and angle brackets' do
        expect(described_class.escape(input)).to eq(output)
      end
    end
  end

  describe '.format_links' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :output) do
      nil                                            | nil
      ''                                             | ''
      '[label](https://gitlab.example.com)'          | '<https://gitlab.example.com|label>'
      '<a href="https://evil.example.com">label</a>' | '<a href="https://evil.example.com">label</a>'
    end

    with_them do
      it 'converts only Markdown links' do
        expect(described_class.format_links(input)).to eq(output)
      end
    end
  end
end
