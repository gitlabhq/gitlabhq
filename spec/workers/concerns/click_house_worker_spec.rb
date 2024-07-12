# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouseWorker, feature_category: :database do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
      include ClickHouseWorker

      def perform
        AnotherWorker.perform_async('identifier')
      end
    end
  end

  let(:another_worker) do
    Class.new do
      def self.name
        'AnotherWorker'
      end

      include ApplicationWorker
    end
  end

  before do
    stub_const('DummyWorker', worker)
    stub_const('AnotherWorker', another_worker)
  end

  describe '.register_click_house_worker?' do
    subject(:register_click_house_worker?) { worker.register_click_house_worker? }

    context 'when click_house_migration_lock is set' do
      before do
        worker.click_house_migration_lock(1.minute)
      end

      it { is_expected.to be(true) }
    end

    context 'when click_house_migration_lock is not set' do
      it { is_expected.to be(true) }
    end

    context 'when worker does not include module' do
      it { expect(another_worker).not_to respond_to(:register_click_house_worker?) }
    end
  end

  describe '.click_house_worker_attrs' do
    subject(:click_house_worker_attrs) { worker.click_house_migration_lock(ttl) }

    let(:ttl) { 1.minute }

    it { expect { click_house_worker_attrs }.not_to raise_error }
    it { is_expected.to match(a_hash_including(migration_lock_ttl: 60.seconds)) }

    context 'with invalid ttl' do
      let(:ttl) { {} }

      it 'raises exception' do
        expect { click_house_worker_attrs }.to raise_error(ArgumentError)
      end
    end
  end

  it 'registers ClickHouse worker' do
    expect(worker.register_click_house_worker?).to be_truthy
    expect(another_worker).not_to respond_to(:register_click_house_worker?)
  end

  it 'sets default TTL for worker registration' do
    expect(worker.click_house_worker_attrs).to match(
      a_hash_including(migration_lock_ttl: ClickHouse::MigrationSupport::ExclusiveLock::DEFAULT_CLICKHOUSE_WORKER_TTL)
    )
  end

  it 'registers worker to pause on ClickHouse migrations' do
    expect(worker.get_pause_control).to eq(:click_house_migration)
    expect(another_worker.get_pause_control).to be_nil
  end

  it 'marks the worker as having external dependencies' do
    expect(worker.worker_has_external_dependencies?).to be_truthy
  end
end
