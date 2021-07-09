# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::SidekiqClientMiddleware do
  let(:middleware) { described_class.new }

  let(:load_balancer) { double.as_null_object }
  let(:worker_class) { 'TestDataConsistencyWorker' }
  let(:job) { { "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e" } }

  before do
    skip_feature_flags_yaml_validation
    skip_default_enabled_yaml_check
    allow(::Gitlab::Database::LoadBalancing).to receive_message_chain(:proxy, :load_balancer).and_return(load_balancer)
  end

  after do
    Gitlab::Database::LoadBalancing::Session.clear_session
  end

  def run_middleware
    middleware.call(worker_class, job, nil, nil) {}
  end

  describe '#call' do
    shared_context 'data consistency worker class' do |data_consistency, feature_flag|
      let(:expected_consistency) { data_consistency }
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

    shared_examples_for 'job data consistency' do
      it "sets job data consistency" do
        run_middleware

        expect(job['worker_data_consistency']).to eq(expected_consistency)
      end
    end

    shared_examples_for 'does not pass database locations' do
      it 'does not pass database locations', :aggregate_failures do
        run_middleware

        expect(job['database_replica_location']).to be_nil
        expect(job['database_write_location']).to be_nil
      end

      include_examples 'job data consistency'
    end

    shared_examples_for 'mark data consistency location' do |data_consistency|
      include_context 'data consistency worker class', data_consistency, :load_balancing_for_test_data_consistency_worker

      let(:location) { '0/D525E3A8' }

      context 'when feature flag is disabled' do
        let(:expected_consistency) { :always }

        before do
          stub_feature_flags(load_balancing_for_test_data_consistency_worker: false)
        end

        include_examples 'does not pass database locations'
      end

      context 'when write was not performed' do
        before do
          allow(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_primary?).and_return(false)
        end

        it 'passes database_replica_location' do
          expect(load_balancer).to receive_message_chain(:host, "database_replica_location").and_return(location)

          run_middleware

          expect(job['database_replica_location']).to eq(location)
        end

        include_examples 'job data consistency'
      end

      context 'when write was performed' do
        before do
          allow(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_primary?).and_return(true)
        end

        it 'passes primary write location', :aggregate_failures do
          expect(load_balancer).to receive(:primary_write_location).and_return(location)

          run_middleware

          expect(job['database_write_location']).to eq(location)
        end

        include_examples 'job data consistency'
      end
    end

    shared_examples_for 'database location was already provided' do |provided_database_location, other_location|
      shared_examples_for 'does not set database location again' do |use_primary|
        before do
          allow(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_primary?).and_return(use_primary)
        end

        it 'does not set database locations again' do
          run_middleware

          expect(job[provided_database_location]).to eq(old_location)
          expect(job[other_location]).to be_nil
        end
      end

      let(:old_location) { '0/D525E3A8' }
      let(:new_location) { 'AB/12345' }
      let(:job) { { "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e", provided_database_location => old_location } }

      before do
        allow(load_balancer).to receive(:primary_write_location).and_return(new_location)
        allow(load_balancer).to receive(:database_replica_location).and_return(new_location)
      end

      context "when write was performed" do
        include_examples 'does not set database location again', true
      end

      context "when write was not performed" do
        include_examples 'does not set database location again', false
      end
    end

    context 'when worker cannot be constantized' do
      let(:worker_class) { 'ActionMailer::MailDeliveryJob' }
      let(:expected_consistency) { :always }

      include_examples 'does not pass database locations'
    end

    context 'when worker class does not include ApplicationWorker' do
      let(:worker_class) { ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper }
      let(:expected_consistency) { :always }

      include_examples 'does not pass database locations'
    end

    context 'database write location was already provided' do
      include_examples 'database location was already provided', 'database_write_location', 'database_replica_location'
    end

    context 'database replica location was already provided' do
      include_examples 'database location was already provided', 'database_replica_location', 'database_write_location'
    end

    context 'when worker data consistency is :always' do
      include_context 'data consistency worker class', :always, :load_balancing_for_test_data_consistency_worker

      include_examples 'does not pass database locations'
    end

    context 'when worker data consistency is :delayed' do
      include_examples  'mark data consistency location', :delayed
    end

    context 'when worker data consistency is :sticky' do
      include_examples  'mark data consistency location', :sticky
    end
  end
end
