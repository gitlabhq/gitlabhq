# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ContainerRegistryEvent do
  let(:secret_token) { 'secret_token' }
  let(:events) { [{ action: 'push' }] }
  let(:registry_headers) { { 'Content-Type' => ::API::ContainerRegistryEvent::DOCKER_DISTRIBUTION_EVENTS_V1_JSON } }

  describe 'POST /container_registry_event/events' do
    before do
      allow(Gitlab.config.registry).to receive(:notification_secret) { secret_token }
    end

    subject do
      post api('/container_registry_event/events'),
           params: { events: events }.to_json,
           headers: registry_headers.merge('Authorization' => secret_token)
    end

    it 'returns 200 status and events are passed to event handler' do
      event = spy(:event)
      allow(::ContainerRegistry::Event).to receive(:new).and_return(event)
      expect(event).to receive(:supported?).and_return(true)

      subject

      expect(event).to have_received(:handle!).once
      expect(event).to have_received(:track!).once
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns 401 error status when token is invalid' do
      post api('/container_registry_event/events'),
           params: { events: events }.to_json,
           headers: registry_headers.merge('Authorization' => 'invalid_token')

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end
end
