# frozen_string_literal: true

require 'spec_helper'

describe OptionallySearch do
  let(:model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'users'

      include OptionallySearch
    end
  end

  describe '.search' do
    it 'raises NotImplementedError' do
      expect { model.search('foo') }.to raise_error(NotImplementedError)
    end
  end

  describe '.optionally_search' do
    context 'when a query is given' do
      it 'delegates to the search method' do
        expect(model)
          .to receive(:search)
          .with('foo')

        model.optionally_search('foo')
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
