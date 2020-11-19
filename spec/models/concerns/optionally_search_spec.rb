# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OptionallySearch do
  describe '.search' do
    let(:model) do
      Class.new do
        include OptionallySearch
      end
    end

    it 'raises NotImplementedError' do
      expect { model.search('foo') }.to raise_error(NotImplementedError)
    end
  end

  describe '.optionally_search' do
    let(:model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'users'

        include OptionallySearch

        def self.search(query, **options)
          [query, options]
        end
      end
    end

    context 'when a query is given' do
      it 'delegates to the search method' do
        expect(model)
          .to receive(:search)
          .with('foo')
          .and_call_original

        expect(model.optionally_search('foo')).to eq(['foo', {}])
      end
    end

    context 'when an option is provided' do
      it 'delegates to the search method' do
        expect(model)
          .to receive(:search)
          .with('foo', some_option: true)
          .and_call_original

        expect(model.optionally_search('foo', some_option: true)).to eq(['foo', { some_option: true }])
      end
    end

    context 'when no query is given' do
      it 'returns the current relation' do
        expect(model.optionally_search).to be_a_kind_of(ActiveRecord::Relation)
      end
    end

    context 'when an empty query is given' do
      it 'returns the current relation' do
        expect(model.optionally_search(''))
          .to be_a_kind_of(ActiveRecord::Relation)
      end
    end
  end
end
