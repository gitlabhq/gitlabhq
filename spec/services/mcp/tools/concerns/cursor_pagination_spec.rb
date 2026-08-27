# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Concerns::CursorPagination, feature_category: :mcp_server do
  let(:test_class) do
    Class.new do
      include Mcp::Tools::Concerns::CursorPagination

      attr_accessor :params

      def initialize(params)
        @params = params
      end
    end
  end

  let(:service) { test_class.new(params) }

  describe '#paginated_first' do
    context 'when first is not provided' do
      let(:params) { {} }

      it 'defaults to DEFAULT_PAGE_SIZE' do
        expect(service.send(:paginated_first)).to eq(described_class::DEFAULT_PAGE_SIZE)
      end
    end

    context 'when first is provided' do
      let(:params) { { first: 5 } }

      it 'returns the provided value' do
        expect(service.send(:paginated_first)).to eq(5)
      end
    end
  end

  describe '.input_schema_params' do
    it 'describes the forward pagination params by default' do
      expect(described_class.input_schema_params(items: 'wiki pages')).to eq({
        first: {
          type: 'integer',
          description: 'Number of wiki pages to return after the cursor (forward pagination). ' \
            'Default 20, max 100.',
          minimum: 1,
          maximum: 100
        },
        after: {
          type: 'string',
          description: 'Cursor for forward pagination of wiki pages. ' \
            'Use pageInfo.endCursor from a previous response.'
        }
      })
    end

    it 'describes the backward pagination params when they are requested' do
      expect(described_class.input_schema_params(items: 'notes', params: %i[last before])).to eq({
        last: {
          type: 'integer',
          description: 'Number of notes to return before the cursor (backward pagination). ' \
            'Default 20, max 100.',
          minimum: 1,
          maximum: 100
        },
        before: {
          type: 'string',
          description: 'Cursor for backward pagination of notes. ' \
            'Use pageInfo.startCursor from a previous response.'
        }
      })
    end

    it 'prefixes the param names and adds the condition they apply to' do
      params = described_class.input_schema_params(
        items: 'notes',
        prefix: 'notes_',
        applies_to: 'notes is in include'
      )

      expect(params.keys).to eq(%i[notes_first notes_after])
      expect(params[:notes_first][:description]).to end_with('Applies only when notes is in include.')
      expect(params[:notes_after][:description]).to end_with('Applies only when notes is in include.')
    end

    it 'omits the default when the tool does not apply one' do
      params = described_class.input_schema_params(items: 'notes', default_page_size: nil)

      expect(params[:first][:description]).to eq(
        'Number of notes to return after the cursor (forward pagination). Max 100.'
      )
    end

    it 'points at the flattened snake_case cursor location when the tool requests it' do
      params = described_class.input_schema_params(items: 'jobs', cursor_style: :snake_case)

      expect(params[:after][:description]).to eq(
        'Cursor for forward pagination of jobs. Use page_info.end_cursor from a previous response.'
      )
    end

    it 'raises for a param it does not know' do
      expect { described_class.input_schema_params(items: 'notes', params: %i[first page]) }
        .to raise_error(ArgumentError, 'Unsupported cursor pagination params: page')
    end

    it 'names every unknown param in the error' do
      expect { described_class.input_schema_params(items: 'notes', params: %i[page per_page]) }
        .to raise_error(ArgumentError, 'Unsupported cursor pagination params: page, per_page')
    end
  end

  # Guards against a tool hardcoding its own page size bounds instead of calling the builder.
  describe 'page size bounds of every registered tool' do
    let(:page_size_properties) do
      Mcp::Tools::Manager.new.tools.flat_map do |name, tool|
        properties = tool.input_schema[:properties] || {}

        properties.filter_map do |property, schema|
          ["#{name}.#{property}", schema] if property.to_s.end_with?('first', 'last', 'page_size')
        end
      end
    end

    it 'uses the shared minimum and maximum' do
      expect(page_size_properties).not_to be_empty

      offenders = page_size_properties.reject do |_, schema|
        schema[:minimum] == described_class::MIN_PAGE_SIZE && schema[:maximum] == described_class::MAX_PAGE_SIZE
      end

      expect(offenders.map(&:first)).to be_empty
    end
  end
end
