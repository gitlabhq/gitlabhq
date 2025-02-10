# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ContainerRegistryEvent, feature_category: :container_registry do
  let(:events) { [{ action: 'push' }, { action: 'pull' }, { action: 'mount' }] }
  let(:registry_headers) do
    { 'Content-Type' => ::API::ContainerRegistryEvent::DOCKER_DISTRIBUTION_EVENTS_V1_JSON }
  end

  let(:base_event) do
    { target: { tag: 'latest', repository: project.full_path } }
  end

  describe 'POST /container_registry_event/events' do
    before do
      allow(Gitlab.config.registry).to receive(:notification_secret).and_return('secret_token')
    end

    shared_context 'with authorization header' do |token|
      let(:headers) { registry_headers.merge('Authorization' => token) }
    end

    def make_post_request(custom_events = events, custom_headers = headers)
      post api('/container_registry_event/events'),
        params: { events: custom_events }.to_json,
        headers: custom_headers
    end

    context 'with valid token' do
      let_it_be(:project) { create(:project) }

      include_context 'with authorization header', 'secret_token'

      it 'processes events successfully' do
        allow_next_instance_of(::ContainerRegistry::Event) do |event|
          next unless event.supported?

          expect(event).to receive(:handle!).once
          expect(event).to receive(:track!).once
        end

        make_post_request

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'with project statistics update events' do
        let(:project_events) do
          [
            base_event.merge(action: 'push'),
            base_event.merge(action: 'delete')
          ]
        end

        it 'enqueues project statistics updates' do
          expect(ProjectCacheWorker)
            .to receive(:perform_async)
                  .with(project.id, [], %w[container_registry_size])
                  .twice.and_call_original

          expect { make_post_request(project_events) }
            .to change { ProjectCacheWorker.jobs.size }.from(0).to(1)
        end
      end

      context 'with invalid repository path' do
        before do
          allow(ContainerRegistry::Path)
            .to receive(:new)
                  .and_raise(ContainerRegistry::Path::InvalidRegistryPathError.new('Invalid registry path'))
        end

        it 'returns bad request status with error message' do
          make_post_request([base_event.merge(action: 'push')])

          expect(response).to have_gitlab_http_status(:bad_request)
          puts "PPP - #{json_response}"
          expect(json_response['message']).to eq('Invalid repository path')
        end
      end
    end

    context 'with invalid token' do
      include_context 'with authorization header', 'invalid_token'

      it 'returns unauthorized status' do
        make_post_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
