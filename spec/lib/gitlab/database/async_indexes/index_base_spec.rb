# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes::IndexBase, feature_category: :database do
  describe '#perform' do
    subject { described_class.new(async_index) }

    let(:async_index) { create(:postgres_async_index) }
    let(:model) { Gitlab::Database.database_base_models[Gitlab::Database::PRIMARY_DATABASE_NAME] }
    let(:connection) { model.connection }

    around do |example|
      Gitlab::Database::SharedModel.using_connection(connection) do
        example.run
      end
    end

    describe '#preconditions_met?' do
      it 'raises errors if preconditions is not defined' do
        expect { subject.perform }.to raise_error NotImplementedError, 'must implement preconditions_met?'
      end
    end

    describe '#action_type' do
      before do
        allow(subject).to receive(:preconditions_met?).and_return(true)
      end

      it 'raises errors if action_type is not defined' do
        expect { subject.perform }.to raise_error NotImplementedError, 'must implement action_type'
      end
    end

    context 'with error handling' do
      before do
        allow(subject).to receive(:preconditions_met?).and_return(true)
        allow(subject).to receive(:action_type).and_return('test')
        allow(async_index.connection).to receive(:execute).and_call_original

        allow(async_index.connection)
          .to receive(:execute)
          .with(async_index.definition)
          .and_raise(ActiveRecord::StatementInvalid)
      end

      context 'on production' do
        before do
          allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(false)
        end

        it 'increases execution attempts' do
          expect { subject.perform }.to change { async_index.attempts }.by(1)

          expect(async_index.last_error).to be_present
          expect(async_index).not_to be_destroyed
        end

        it 'logs an error message including the index_name' do
          expect(Gitlab::AppLogger)
            .to receive(:error)
            .with(a_hash_including(:message, :index_name))
            .and_call_original

          subject.perform
        end
      end

      context 'on development' do
        it 'also raises errors' do
          expect { subject.perform }
            .to raise_error(ActiveRecord::StatementInvalid)
            .and change { async_index.attempts }.by(1)

          expect(async_index.last_error).to be_present
          expect(async_index).not_to be_destroyed
        end
      end
    end
  end
end
