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
      expect_next(WebHookService, project_hook, data.with_indifferent_access, hook_name, anything,
        idempotency_key: anything)
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

      expect_next(WebHookService, project_hook, data.with_indifferent_access, hook_name, anything,
        idempotency_key: anything)
        .to receive(:execute).and_return(response)
      expect(subject).to receive(:log_extra_metadata_on_done).with(:response_status, response.status)
      expect(subject).to receive(:log_extra_metadata_on_done).with(:http_status, response[:http_status])

      expect { subject.perform(project_hook.id, data, hook_name, params) }
        .to change { Gitlab::WebHooks::RecursionDetection::UUID.instance.request_uuid }.to(uuid)
    end

    it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

    context 'when object is wiki_page' do
      let_it_be(:container) { create(:project) }
      let_it_be(:wiki) { container.wiki }
      let_it_be(:content) { 'test content' }
      let_it_be(:wiki_page) { create(:wiki_page, container: container, content: content) }

      let(:object_kind) { 'wiki_page' }
      let(:slug) { wiki_page.slug }
      let(:version_id) { wiki_page.version.id }
      let(:args) do
        {
          object_kind: object_kind,
          project: {
            id: container.id
          },
          object_attributes: {
            slug: slug,
            version_id: version_id
          }
        }
      end

      it 'injects content into wiki_page' do
        expected_data = args.deep_merge(object_attributes: { content: content })

        expect(ProjectWiki).to receive(:find_by_id).with(container.id).and_return(wiki)
        expect(wiki).to receive(:find_page).with(slug, version_id).and_return(wiki_page)
        expect_next(WebHookService, project_hook, expected_data.with_indifferent_access, hook_name, anything,
          idempotency_key: anything)
          .to receive(:execute).and_return(response)
        expect(subject).to receive(:log_extra_metadata_on_done).with(:response_status, response.status)
        expect(subject).to receive(:log_extra_metadata_on_done).with(:http_status, response[:http_status])

        subject.perform(project_hook.id, args, hook_name)
      end

      context 'when parameter slug empty' do
        let(:slug) { '' }

        it 'uses existing data' do
          expected_data = args

          expect_next(WebHookService, project_hook, expected_data.with_indifferent_access, hook_name, anything,
            idempotency_key: anything)
            .to receive(:execute).and_return(response)
          expect(subject).to receive(:log_extra_metadata_on_done).with(:response_status, response.status)
          expect(subject).to receive(:log_extra_metadata_on_done).with(:http_status, response[:http_status])

          subject.perform(project_hook.id, args, hook_name)
        end
      end

      context 'when parameter version_id empty' do
        let(:version_id) { '' }

        it 'uses existing data' do
          expected_data = args

          expect_next(WebHookService, project_hook, expected_data.with_indifferent_access, hook_name, anything,
            idempotency_key: anything)
            .to receive(:execute).and_return(response)
          expect(subject).to receive(:log_extra_metadata_on_done).with(:response_status, response.status)
          expect(subject).to receive(:log_extra_metadata_on_done).with(:http_status, response[:http_status])

          subject.perform(project_hook.id, args, hook_name)
        end
      end

      context 'when wiki empty' do
        it 'uses existing data' do
          expected_data = args

          expect(ProjectWiki).to receive(:find_by_id).with(container.id).and_return(nil)
          expect_next(WebHookService, project_hook, expected_data.with_indifferent_access, hook_name, anything,
            idempotency_key: anything)
            .to receive(:execute).and_return(response)
          expect(subject).to receive(:log_extra_metadata_on_done).with(:response_status, response.status)
          expect(subject).to receive(:log_extra_metadata_on_done).with(:http_status, response[:http_status])

          subject.perform(project_hook.id, args, hook_name)
        end
      end

      context 'when wiki page empty' do
        it 'uses existing data' do
          expected_data = args

          expect(ProjectWiki).to receive(:find_by_id).with(container.id).and_return(wiki)
          expect(wiki).to receive(:find_page).with(slug, version_id).and_return(nil)
          expect_next(WebHookService, project_hook, expected_data.with_indifferent_access, hook_name, anything,
            idempotency_key: anything)
            .to receive(:execute).and_return(response)
          expect(subject).to receive(:log_extra_metadata_on_done).with(:response_status, response.status)
          expect(subject).to receive(:log_extra_metadata_on_done).with(:http_status, response[:http_status])

          subject.perform(project_hook.id, args, hook_name)
        end
      end
    end
  end
end
