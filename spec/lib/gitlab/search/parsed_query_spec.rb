# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::ParsedQuery, feature_category: :global_search do
  let(:term) { 'search term' }
  let(:filters) { [] }

  subject(:parsed_query) { described_class.new(term, filters) }

  describe '#initialize' do
    it 'sets term' do
      expect(parsed_query.term).to eq(term)
    end

    it 'sets filters' do
      expect(parsed_query.filters).to eq(filters)
    end
  end

  describe '#filter_results' do
    let(:results) { [result1, result2, result3] }
    let(:result1) { instance_double(Project, name: 'foo.rb', path: 'app/models') }
    let(:result2) { instance_double(Project, name: 'bar.js', path: 'app/assets') }
    let(:result3) { instance_double(Project, name: 'baz.rb', path: 'lib/utils') }

    context 'when there are no filters' do
      it 'returns nil' do
        expect(parsed_query.filter_results(results)).to be_nil
      end
    end

    context 'when filters have no matchers' do
      let(:filters) do
        [
          { name: :filename, value: 'test.rb', negated: false },
          { name: :extension, value: 'rb', negated: true }
        ]
      end

      it 'returns nil' do
        expect(parsed_query.filter_results(results)).to be_nil
      end
    end

    context 'with including filters' do
      let(:filters) do
        [
          {
            name: :extension,
            value: 'rb',
            negated: false,
            matcher: ->(_filter, result) { result.name.end_with?('.rb') }
          }
        ]
      end

      it 'filters results to only include matching items' do
        filtered = parsed_query.filter_results(results)

        expect(filtered).to contain_exactly(result1, result3)
      end
    end

    context 'with excluding filters' do
      let(:filters) do
        [
          {
            name: :extension,
            value: 'rb',
            negated: true,
            matcher: ->(_filter, result) { result.name.end_with?('.rb') }
          }
        ]
      end

      it 'filters results to exclude matching items' do
        filtered = parsed_query.filter_results(results)

        expect(filtered).to contain_exactly(result2)
      end
    end

    context 'with multiple including filters' do
      let(:filters) do
        [
          {
            name: :extension,
            value: 'rb',
            negated: false,
            matcher: ->(_filter, result) { result.name.end_with?('.rb') }
          },
          {
            name: :path,
            value: 'app',
            negated: false,
            matcher: ->(_filter, result) { result.path.start_with?('app') }
          }
        ]
      end

      it 'filters results matching all conditions' do
        filtered = parsed_query.filter_results(results)

        expect(filtered).to contain_exactly(result1)
      end
    end

    context 'with multiple excluding filters' do
      let(:filters) do
        [
          {
            name: :extension,
            value: 'rb',
            negated: true,
            matcher: ->(_filter, result) { result.name.end_with?('.rb') }
          },
          {
            name: :path,
            value: 'app',
            negated: true,
            matcher: ->(_filter, result) { result.path.start_with?('app') }
          }
        ]
      end

      it 'filters results excluding any matching conditions' do
        filtered = parsed_query.filter_results(results)

        expect(filtered).to be_empty
      end
    end

    context 'with both including and excluding filters' do
      let(:filters) do
        [
          {
            name: :extension,
            value: 'rb',
            negated: false,
            matcher: ->(_filter, result) { result.name.end_with?('.rb') }
          },
          {
            name: :path,
            value: 'app',
            negated: true,
            matcher: ->(_filter, result) { result.path.start_with?('app') }
          }
        ]
      end

      it 'applies both including and excluding filters' do
        filtered = parsed_query.filter_results(results)

        expect(filtered).to contain_exactly(result3)
      end
    end

    context 'with mixed filters with and without matchers' do
      let(:filters) do
        [
          {
            name: :extension,
            value: 'rb',
            negated: false,
            matcher: ->(_filter, result) { result.name.end_with?('.rb') }
          },
          {
            name: :filename,
            value: 'test.rb',
            negated: false
          }
        ]
      end

      it 'only applies filters with matchers' do
        filtered = parsed_query.filter_results(results)

        expect(filtered).to contain_exactly(result1, result3)
      end
    end

    context 'when results array is modified' do
      let(:filters) do
        [
          {
            name: :extension,
            value: 'rb',
            negated: false,
            matcher: ->(_filter, result) { result.name.end_with?('.rb') }
          }
        ]
      end

      it 'modifies the original results array' do
        original_results = results.dup
        parsed_query.filter_results(results)

        expect(results).not_to eq(original_results)
        expect(results).to contain_exactly(result1, result3)
      end
    end
  end
end
