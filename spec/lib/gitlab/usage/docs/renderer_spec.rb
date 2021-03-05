# frozen_string_literal: true

require 'spec_helper'

CODE_REGEX = %r{<code>(.*)</code>}.freeze

RSpec.describe Gitlab::Usage::Docs::Renderer do
  describe 'contents' do
    let(:dictionary_path) { Gitlab::Usage::Docs::Renderer::DICTIONARY_PATH }
    let(:items) { Gitlab::Usage::MetricDefinition.definitions.first(10).to_h }

    it 'generates dictionary for given items' do
      generated_dictionary = described_class.new(items).contents

      generated_dictionary_keys = RDoc::Markdown
        .parse(generated_dictionary)
        .table_of_contents
        .select { |metric_doc| metric_doc.level == 3 }
        .map { |item| item.text.match(CODE_REGEX)&.captures&.first }

      expect(generated_dictionary_keys).to match_array(items.keys)
    end
  end
end
