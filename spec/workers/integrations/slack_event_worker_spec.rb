# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackEventWorker, :clean_gitlab_redis_shared_state,
  feature_category: :integrations do
  describe '.event?' do
    subject { described_class.event?(event) }

    context 'when event is known' do
      let(:event) { 'app_home_opened' }

      it { is_expected.to eq(true) }
    end

    context 'when event is not known' do
      let(:event) { 'foo' }

      it { is_expected.to eq(false) }
    end
  end

  describe '#perform' do
    let(:worker) { described_class.new }
    let(:event) { 'app_home_opened' }
    let(:service_class) { ::Integrations::SlackEvents::AppHomeOpenedService }

    let(:args) do
      {
        slack_event: event,
        params: params
      }
    end

    let(:params) do
      {
        team_id: "T0123A456BC",
        event: { user: "U0123ABCDEF" },
        event_id: "Ev03SA75UJKB"
      }
    end

    shared_examples 'logs extra metadata on done' do
      specify do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:slack_event, event)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:slack_user_id, 'U0123ABCDEF')
        expect(worker).to receive(:log_extra_metadata_on_done).with(:slack_workspace_id, 'T0123A456BC')

        worker.perform(args)
      end
    end

    it 'executes the correct service' do
      expect_next_instance_of(service_class, params) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      worker.perform(args)
    end

    it_behaves_like 'logs extra metadata on done'

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [args] }
    end

    it 'ensures idempotency when called twice by only executing service once' do
      expect_next_instances_of(service_class, 1, params) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      worker.perform(args)
      worker.perform(args)
    end

    it 'executes service twice if service returned an error' do
      expect_next_instances_of(service_class, 2, params) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.error(message: 'foo'))
      end

      worker.perform(args)
      worker.perform(args)
    end

    it 'executes service twice if service raised an error' do
      expect_next_instances_of(service_class, 2, params) do |service|
        expect(service).to receive(:execute).and_raise(ArgumentError)
      end

      expect { worker.perform(args) }.to raise_error(ArgumentError)
      expect { worker.perform(args) }.to raise_error(ArgumentError)
    end

    it 'executes service twice when event_id is different' do
      second_params = params.dup
      second_args = args.dup
      second_params[:event_id] = 'foo'
      second_args[:params] = second_params

      expect_next_instances_of(service_class, 1, params) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      expect_next_instances_of(service_class, 1, second_params) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      worker.perform(args)
      worker.perform(second_args)
    end

    context 'when event is not known' do
      let(:event) { 'foo' }

      it 'does not execute the service class' do
        expect(service_class).not_to receive(:new)

        worker.perform(args)
      end

      it 'logs an error' do
        expect(Sidekiq.logger).to receive(:error).with({ message: 'Unknown slack_event', slack_event: event })

        worker.perform(args)
      end

      it_behaves_like 'logs extra metadata on done'
    end
  end
end
