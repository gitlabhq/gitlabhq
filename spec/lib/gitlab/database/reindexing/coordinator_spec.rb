# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing::Coordinator do
  include ExclusiveLeaseHelpers

  describe '.perform' do
    subject { described_class.new(indexes).perform }

    let(:indexes) { [instance_double(Gitlab::Database::PostgresIndex), instance_double(Gitlab::Database::PostgresIndex)] }
    let(:reindexers) { [instance_double(Gitlab::Database::Reindexing::ConcurrentReindex), instance_double(Gitlab::Database::Reindexing::ConcurrentReindex)] }

    let!(:lease) { stub_exclusive_lease(lease_key, uuid, timeout: lease_timeout) }
    let(:lease_key) { 'gitlab/database/reindexing/coordinator' }
    let(:lease_timeout) { 1.day }
    let(:uuid) { 'uuid' }

    before do
      allow(Gitlab::Database::Reindexing::ReindexAction).to receive(:keep_track_of).and_yield

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

    context 'locking' do
      it 'acquires a lock while reindexing' do
        indexes.each do |index|
          expect(lease).to receive(:try_obtain).ordered.and_return(uuid)
          action = instance_double(Gitlab::Database::Reindexing::ConcurrentReindex)
          expect(Gitlab::Database::Reindexing::ConcurrentReindex).to receive(:new).ordered.with(index).and_return(action)
          expect(action).to receive(:perform).ordered
          expect(Gitlab::ExclusiveLease).to receive(:cancel).ordered.with(lease_key, uuid)
        end

        subject
      end

      it 'does does not perform reindexing actions if lease is not granted' do
        indexes.each do |index|
          expect(lease).to receive(:try_obtain).ordered.and_return(false)
          expect(Gitlab::Database::Reindexing::ConcurrentReindex).not_to receive(:new)
        end

        subject
      end
    end
  end
end
