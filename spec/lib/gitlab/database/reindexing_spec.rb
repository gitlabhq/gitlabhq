# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing do
  describe '.perform' do
    before do
      allow(Gitlab::Database::Reindexing::ReindexAction).to receive(:keep_track_of).and_yield
    end

    shared_examples_for 'reindexing' do
      before do
        indexes.zip(reindexers).each do |index, reindexer|
          allow(Gitlab::Database::Reindexing::ConcurrentReindex).to receive(:new).with(index).and_return(reindexer)
          allow(reindexer).to receive(:perform)
        end
      end

      it 'performs concurrent reindexing for each index' do
        indexes.zip(reindexers).each do |index, reindexer|
          expect(Gitlab::Database::Reindexing::ConcurrentReindex).to receive(:new).with(index).ordered.and_return(reindexer)
          expect(reindexer).to receive(:perform)
        end

        subject
      end

      it 'keeps track of actions and creates ReindexAction records' do
        indexes.each do |index|
          expect(Gitlab::Database::Reindexing::ReindexAction).to receive(:keep_track_of).with(index).and_yield
        end

        subject
      end
    end

    context 'with multiple indexes' do
      subject { described_class.perform(indexes) }

      let(:indexes) { [instance_double('Gitlab::Database::PostgresIndex'), instance_double('Gitlab::Database::PostgresIndex')] }
      let(:reindexers) { [instance_double('Gitlab::Database::Reindexing::ConcurrentReindex'), instance_double('Gitlab::Database::Reindexing::ConcurrentReindex')] }

      it_behaves_like 'reindexing'
    end

    context 'single index' do
      subject { described_class.perform(indexes.first) }

      let(:indexes) { [instance_double('Gitlab::Database::PostgresIndex')] }
      let(:reindexers) { [instance_double('Gitlab::Database::Reindexing::ConcurrentReindex')] }

      it_behaves_like 'reindexing'
    end
  end
end
