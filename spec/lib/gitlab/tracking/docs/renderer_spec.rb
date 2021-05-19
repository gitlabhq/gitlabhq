# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Docs::Renderer do
  describe 'contents' do
    let(:dictionary_path) { described_class::DICTIONARY_PATH }
    let(:items) { Gitlab::Tracking::EventDefinition.definitions.first(10).to_h }

    it 'generates dictionary for given items' do
      generated_dictionary = described_class.new(items).contents
      table_of_contents_items = items.values.map { |item| "#{item.category} #{item.action}"}

      generated_dictionary_keys = RDoc::Markdown
        .parse(generated_dictionary)
        .table_of_contents
        .select { |metric_doc| metric_doc.level == 3 }
        .map { |item| item.text.match(%r{<code>(.*)</code>})&.captures&.first }

      expect(generated_dictionary_keys).to match_array(table_of_contents_items)
    end
  end
end
