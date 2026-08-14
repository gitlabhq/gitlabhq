# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Analytics::Glql::Schema, feature_category: :custom_dashboards_foundation do
  after do
    described_class.instance_variable_set(:@document, nil)
  end

  describe '.document' do
    it 'adds the display_types block' do
      expect(::Glql.schema).not_to have_key('display_types')

      expect(described_class.document['display_types']).to eq(described_class::DISPLAY_TYPES)
    end

    it 'passes the rest of the gem document through untouched' do
      expect(described_class.document.except('display_types')).to eq(::Glql.schema)
    end

    it 'is memoized' do
      expect(described_class.document).to equal(described_class.document)
    end

    # Plain examples rather than a `where` table, which must not take procs.
    describe 'immutability' do
      {
        'the top level' => ->(doc) { doc['sources'] = [] },
        'a block the gem owns' => ->(doc) { doc['sources'] << {} },
        'a source' => ->(doc) { doc['sources'][0]['name'] = 'x' },
        'a mode' => ->(doc) { doc['sources'][0]['modes'][0]['mode'] = 'x' },
        'a filter field' => ->(doc) { doc['sources'][0]['modes'][0]['filter_fields'] << {} },
        'a hash key' => ->(doc) { doc.each_key.first << 'x' },
        'the display types' => ->(doc) { doc['display_types'] << {} },
        'a display type entry' => ->(doc) { doc['display_types'][0]['name'] = 'x' },
        'a leaf string' => ->(doc) { doc['display_types'][0]['name'] << 'x' }
      }.each do |description, mutate|
        it "refuses mutation of #{description}" do
          expect { mutate.call(described_class.document) }.to raise_error(FrozenError)
        end
      end
    end
  end

  describe 'DISPLAY_TYPES' do
    let(:js_path) { Rails.root.join('app/assets/javascripts/glql/constants.js') }

    it 'stays in sync with DISPLAY_TYPES in the frontend constants' do
      body = File.read(js_path)[/export const DISPLAY_TYPES = \{(.*?)\};/m, 1]
      raise "DISPLAY_TYPES not found in #{js_path}" if body.nil?

      frontend = body.scan(/'([^']+)'/).flatten
      raise "no display type names found in #{js_path}" if frontend.empty?

      expect(described_class::DISPLAY_TYPES.map { |type| type['name'] }).to match_array(frontend),
        "DISPLAY_TYPES is out of sync with #{js_path}. A type listed here but not there reaches " \
          "users as an error in the block."
    end
  end
end
