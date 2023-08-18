# frozen_string_literal: true
require 'spec_helper'

RSpec.describe WebHookWorker, feature_category: :integrations do
  include AfterNextHelpers

  let_it_be(:project_hook) { create(:project_hook) }
  let_it_be(:data) { { foo: 'bar' } }
  let_it_be(:hook_name) { 'push_hooks' }
  let_it_be(:response) { ServiceResponse.success }

  describe '#perform' do
    it 'delegates to WebHookService' do
      expect_next(WebHookService, project_hook, data.with_indifferent_access, hook_name, anything)
        .to receive(:execute).and_return(response)
      expect(subject).to receive(:log_extra_metadata_on_done).with(:response_status, response.status)
      expect(subject).to receive(:log_extra_metadata_on_done).with(:http_status, response[:http_status])

      subject.perform(project_hook.id, data, hook_name)
    end

    it 'does not error when the WebHook record cannot be found' do
      expect { subject.perform(non_existing_record_id, data, hook_name) }.not_to raise_error
    end

    it 'retrieves recursion detection data and reinstates it', :request_store, :aggregate_failures do
      uuid = SecureRandom.uuid
      params = { recursion_detection_request_uuid: uuid }

      expect_next(WebHookService, project_hook, data.with_indifferent_access, hook_name, anything)
        .to receive(:execute).and_return(response)
      expect(subject).to receive(:log_extra_metadata_on_done).with(:response_status, response.status)
      expect(subject).to receive(:log_extra_metadata_on_done).with(:http_status, response[:http_status])

      expect { subject.perform(project_hook.id, data, hook_name, params) }
        .to change { Gitlab::WebHooks::RecursionDetection::UUID.instance.request_uuid }.to(uuid)
    end

    it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed
  end
end
