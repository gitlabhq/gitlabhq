# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing do
  describe '.perform' do
    context 'multiple indexes' do
      let(:indexes) { [double, double] }
      let(:reindexers) { [double, double] }

      it 'performs concurrent reindexing for each index' do
        indexes.zip(reindexers).each do |index, reindexer|
          expect(Gitlab::Database::Reindexing::ConcurrentReindex).to receive(:new).with(index).ordered.and_return(reindexer)
          expect(reindexer).to receive(:perform)
        end

        described_class.perform(indexes)
      end
    end

    context 'single index' do
      let(:index) { double }
      let(:reindexer) { double }

      it 'performs concurrent reindexing for single index' do
        expect(Gitlab::Database::Reindexing::ConcurrentReindex).to receive(:new).with(index).and_return(reindexer)
        expect(reindexer).to receive(:perform)

        described_class.perform(index)
      end
    end
  end
end
