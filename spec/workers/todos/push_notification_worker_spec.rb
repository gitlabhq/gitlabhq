# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::PushNotificationWorker, feature_category: :notifications do
  let_it_be(:todo) { create(:todo) }

  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [[todo.id]] }
  end

  describe '#perform' do
    it 'runs the delivery service and logs its tallies' do
      response = ServiceResponse.success(
        payload: { todo_count: 1, subscription_count: 0, results: { 'skipped_no_subscription' => 1 }, apns_results: {} }
      )
      service = instance_double(::Notifications::MobilePush::SendTodoNotificationsService, execute: response)
      expect(::Notifications::MobilePush::SendTodoNotificationsService)
        .to receive(:new).with([todo.id]).and_return(service)

      expect(worker).to receive(:log_extra_metadata_on_done).with(:todo_count, 1)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:subscription_count, 0)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:results, { 'skipped_no_subscription' => 1 })
      expect(worker).to receive(:log_extra_metadata_on_done).with(:apns_results, {})

      worker.perform([todo.id])
    end
  end
end
