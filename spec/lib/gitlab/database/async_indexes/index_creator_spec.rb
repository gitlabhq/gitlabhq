# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes::IndexCreator do
  describe '#perform' do
    subject { described_class.new(async_index) }

    let(:async_index) { create(:postgres_async_index) }

    let(:index_model) { Gitlab::Database::AsyncIndexes::PostgresAsyncIndex }

    let(:connection) { ApplicationRecord.connection }

    context 'when the index already exists' do
      before do
        connection.execute(async_index.definition)
      end

      it 'skips index creation' do
        expect(connection).not_to receive(:execute).with(/CREATE INDEX/)

        subject.perform
      end
    end

    it 'creates the index while controlling statement timeout' do
      allow(connection).to receive(:execute).and_call_original
      expect(connection).to receive(:execute).with("SET statement_timeout TO '32400s'").ordered.and_call_original
      expect(connection).to receive(:execute).with(async_index.definition).ordered.and_call_original
      expect(connection).to receive(:execute).with("RESET statement_timeout").ordered.and_call_original

      subject.perform
    end

    it 'removes the index preparation record from postgres_async_indexes' do
      expect(async_index).to receive(:destroy).and_call_original

      expect { subject.perform }.to change { index_model.count }.by(-1)
    end

    it 'skips logic if not able to acquire exclusive lease' do
      expect(subject).to receive(:try_obtain_lease).and_return(false)
      expect(connection).not_to receive(:execute).with(/CREATE INDEX/)
      expect(async_index).not_to receive(:destroy)

      expect { subject.perform }.not_to change { index_model.count }
    end
  end
end
