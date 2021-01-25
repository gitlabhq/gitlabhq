# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Docs::Renderer do
  describe 'contents' do
    let(:dictionary_path) { Gitlab::Usage::Docs::Renderer::DICTIONARY_PATH }
    let(:items) { Gitlab::Usage::MetricDefinition.definitions }

    it 'generates dictionary for given items' do
      generated_dictionary = described_class.new(items).contents
      generated_dictionary_keys = RDoc::Markdown
        .parse(generated_dictionary)
        .table_of_contents
        .select { |metric_doc| metric_doc.level == 2 && !metric_doc.text.start_with?('info:') }
        .map(&:text)

      expect(generated_dictionary_keys).to match_array(items.keys)
    end
  end
end
