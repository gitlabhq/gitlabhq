# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::SidekiqServerMiddleware do
  let(:middleware) { described_class.new }

  let(:load_balancer) { double.as_null_object }

  let(:worker) { worker_class.new }
  let(:job) { { "retry" => 3, "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e", 'database_replica_location' => '0/D525E3A8' } }

  before do
    skip_feature_flags_yaml_validation
    skip_default_enabled_yaml_check
    allow(::Gitlab::Database::LoadBalancing).to receive_message_chain(:proxy, :load_balancer).and_return(load_balancer)

    replication_lag!(false)
  end

  after do
    Gitlab::Database::LoadBalancing::Session.clear_session
  end

  describe '#call' do
    shared_context 'data consistency worker class' do |data_consistency, feature_flag|
      let(:worker_class) do
        Class.new do
          def self.name
            'TestDataConsistencyWorker'
          end

          include ApplicationWorker

          data_consistency data_consistency, feature_flag: feature_flag

          def perform(*args)
          end
        end
      end

      before do
        stub_const('TestDataConsistencyWorker', worker_class)
      end
    end

    shared_examples_for 'load balancing strategy' do |strategy|
      it "sets load balancing strategy to #{strategy}" do
        run_middleware do
          expect(job['load_balancing_strategy']).to eq(strategy)
        end
      end
    end

    shared_examples_for 'stick to the primary' do |expected_strategy|
      it 'sticks to the primary' do
        run_middleware do
          expect(Gitlab::Database::LoadBalancing::Session.current.use_primary?).to be_truthy
        end
      end

      include_examples 'load balancing strategy', expected_strategy
    end

    shared_examples_for 'replica is up to date' do |location, expected_strategy|
      it 'does not stick to the primary', :aggregate_failures do
        expect(middleware).to receive(:replica_caught_up?).with(location).and_return(true)

        run_middleware do
          expect(Gitlab::Database::LoadBalancing::Session.current.use_primary?).not_to be_truthy
        end
      end

      include_examples 'load balancing strategy', expected_strategy
    end

    shared_examples_for 'sticks based on data consistency' do |data_consistency|
      include_context 'data consistency worker class', data_consistency, :load_balancing_for_test_data_consistency_worker

      context 'when load_balancing_for_test_data_consistency_worker is disabled' do
        before do
          stub_feature_flags(load_balancing_for_test_data_consistency_worker: false)
        end

        include_examples 'stick to the primary', 'primary'
      end

      context 'when database replica location is set' do
        let(:job) { { 'job_id' => 'a180b47c-3fd6-41b8-81e9-34da61c3400e', 'database_replica_location' => '0/D525E3A8' } }

        before do
          allow(middleware).to receive(:replica_caught_up?).and_return(true)
        end

        it_behaves_like 'replica is up to date', '0/D525E3A8', 'replica'
      end

      context 'when database primary location is set' do
        let(:job) { { 'job_id' => 'a180b47c-3fd6-41b8-81e9-34da61c3400e', 'database_write_location' => '0/D525E3A8' } }

        before do
          allow(middleware).to receive(:replica_caught_up?).and_return(true)
        end

        it_behaves_like 'replica is up to date', '0/D525E3A8', 'replica'
      end

      context 'when database location is not set' do
        let(:job) { { 'job_id' => 'a180b47c-3fd6-41b8-81e9-34da61c3400e' } }

        it_behaves_like 'stick to the primary', 'primary_no_wal'
      end
    end

    context 'when worker class does not include ApplicationWorker' do
      let(:worker) { ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper.new }

      include_examples 'stick to the primary', 'primary'
    end

    context 'when worker data consistency is :always' do
      include_context 'data consistency worker class', :always, :load_balancing_for_test_data_consistency_worker

      include_examples 'stick to the primary', 'primary'
    end

    context 'when worker data consistency is :delayed' do
      include_examples 'sticks based on data consistency', :delayed

      context 'when replica is not up to date' do
        before do
          replication_lag!(true)
        end

        around do |example|
          with_sidekiq_server_middleware do |chain|
            chain.add described_class
            Sidekiq::Testing.disable! { example.run }
          end
        end

        context 'when job is executed first' do
          it 'raises an error and retries', :aggregate_failures do
            expect do
              process_job(job)
            end.to raise_error(Sidekiq::JobRetry::Skip)

            expect(job['error_class']).to eq('Gitlab::Database::LoadBalancing::SidekiqServerMiddleware::JobReplicaNotUpToDate')
          end

          include_examples 'load balancing strategy', 'retry'
        end

        context 'when job is retried' do
          before do
            expect do
              process_job(job)
            end.to raise_error(Sidekiq::JobRetry::Skip)
          end

          context 'and replica still lagging behind' do
            include_examples 'stick to the primary', 'primary'
          end

          context 'and replica is now up-to-date' do
            before do
              replication_lag!(false)
            end

            it_behaves_like 'replica is up to date', '0/D525E3A8', 'replica_retried'
          end
        end
      end
    end

    context 'when worker data consistency is :sticky' do
      include_examples 'sticks based on data consistency', :sticky

      context 'when replica is not up to date' do
        before do
          allow(middleware).to receive(:replica_caught_up?).and_return(false)
        end

        include_examples 'stick to the primary', 'primary'
      end
    end
  end

  def process_job(job)
    Sidekiq::JobRetry.new.local(worker_class, job, 'default') do
      worker_class.process_job(job)
    end
  end

  def run_middleware
    middleware.call(worker, job, double(:queue)) { yield }
  rescue described_class::JobReplicaNotUpToDate
    # we silence errors here that cause the job to retry
  end

  def replication_lag!(exists)
    allow(load_balancer).to receive(:select_up_to_date_host).and_return(!exists)
  end
end
