# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::SidekiqClientMiddleware, feature_category: :database do
  let(:middleware) { described_class.new }

  let(:worker_class) { 'TestDataConsistencyWorker' }
  let(:job) { { "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e" } }

  before do
    skip_default_enabled_yaml_check
  end

  after do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
  end

  def run_middleware
    middleware.call(worker_class, job, nil, nil) {}
  end

  describe '#call', :database_replica do
    shared_context 'data consistency worker class' do |data_consistency, feature_flag|
      let(:expected_consistency) { data_consistency }
      let(:worker_class) do
        Class.new do
          def self.name
            'TestDataConsistencyWorker'
          end

          include ApplicationWorker

          data_consistency data_consistency, feature_flag: feature_flag

          def perform(*args); end
        end
      end

      before do
        stub_const('TestDataConsistencyWorker', worker_class)
      end
    end

    shared_examples_for 'job data consistency' do
      it "sets job data consistency" do
        run_middleware

        expect(job['worker_data_consistency']).to eq(expected_consistency)
      end
    end

    shared_examples_for 'does not pass database locations' do
      it 'does not pass database locations', :aggregate_failures do
        run_middleware

        expect(job['wal_locations']).to be_nil
        expect(job['wal_location_sources']).to be_nil
      end

      include_examples 'job data consistency'
    end

    shared_examples_for 'mark data consistency location' do |data_consistency, worker_klass|
      let(:location) { '0/D525E3A8' }
      include_context 'when tracking WAL location reference'

      if worker_klass
        let(:worker_class) { worker_klass }
        let(:expected_consistency) { data_consistency }
      else
        include_context 'data consistency worker class', data_consistency, :load_balancing_for_test_data_consistency_worker
      end

      context 'when write was not performed' do
        before do
          stub_no_writes_performed!
        end

        context 'when replica hosts are available' do
          it 'passes database_replica_location' do
            expected_locations = expect_tracked_locations_when_replicas_available
            expected_sources = expected_locations.keys.index_with { |_| :replica }

            run_middleware

            expect(job['wal_locations']).to eq(expected_locations)
            expect(job['wal_location_sources']).to eq(expected_sources)
          end
        end

        context 'when no replica hosts are available' do
          it 'passes primary_write_location' do
            expected_locations = expect_tracked_locations_when_no_replicas_available
            expected_sources = expected_locations.keys.index_with { |_| :replica }

            run_middleware

            expect(job['wal_locations']).to eq(expected_locations)
            expect(job['wal_location_sources']).to eq(expected_sources)
          end
        end

        include_examples 'job data consistency'
      end

      context 'when write was performed' do
        before do
          stub_write_performed!
        end

        it 'passes primary write location', :aggregate_failures do
          expected_locations = expect_tracked_locations_from_primary_only
          expected_sources = expected_locations.keys.index_with { |_| :primary }

          run_middleware

          expect(job['wal_locations']).to eq(expected_locations)
          expect(job['wal_location_sources']).to eq(expected_sources)
        end

        include_examples 'job data consistency'
      end
    end

    context 'when worker cannot be constantized' do
      let(:worker_class) { 'InvalidWorker' }
      let(:expected_consistency) { :always }

      include_examples 'does not pass database locations'
    end

    context 'when worker class does not include ApplicationWorker' do
      let(:worker_class) { Gitlab::SidekiqConfig::DummyWorker }
      let(:expected_consistency) { :always }

      include_examples 'does not pass database locations'
    end

    context 'when job contains wrapped worker' do
      let(:worker_class) { ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper }

      context 'when wrapped worker does not include WorkerAttributes' do
        let(:job) { { "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e", "wrapped" => Gitlab::SidekiqConfig::DummyWorker } }
        let(:expected_consistency) { :always }

        include_examples 'does not pass database locations'
      end

      context 'when wrapped worker includes WorkerAttributes' do
        let(:job) { { "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e", "wrapped" => ActionMailer::MailDeliveryJob } }

        include_examples 'mark data consistency location', :delayed, ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper
      end
    end

    context 'database wal location was already provided' do
      let(:old_location) { '0/D525E3A8' }
      let(:new_location) { 'AB/12345' }
      let(:wal_locations) { { Gitlab::Database::MAIN_DATABASE_NAME.to_sym => old_location } }
      let(:job) { { "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e", 'wal_locations' => wal_locations } }
      let(:session) { Gitlab::Database::LoadBalancing::Session.new }

      before do
        Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
          allow(lb).to receive(:primary_write_location).and_return(new_location)
          allow(lb).to receive(:database_replica_location).and_return(new_location)
        end
      end

      shared_examples_for 'does not set database location again' do |use_primary|
        before do
          allow(Gitlab::Database::LoadBalancing::SessionMap).to receive(:current).and_return(session)
          allow(session).to receive(:use_primary?).and_return(use_primary)
        end

        it 'does not set database locations again' do
          run_middleware

          expect(job['wal_locations']).to eq(wal_locations)
          expect(job['wal_location_sources']).to be_nil
        end
      end

      context "when write was performed" do
        include_examples 'does not set database location again', true
      end

      context "when write was not performed" do
        include_examples 'does not set database location again', false
      end
    end

    context 'when worker data consistency is :always' do
      include_context 'data consistency worker class', :always, :load_balancing_for_test_data_consistency_worker

      include_examples 'does not pass database locations'
    end

    context 'when worker data consistency is :delayed' do
      include_examples 'mark data consistency location', :delayed
    end

    context 'when worker data consistency is :sticky' do
      include_examples 'mark data consistency location', :sticky
    end
  end
end
