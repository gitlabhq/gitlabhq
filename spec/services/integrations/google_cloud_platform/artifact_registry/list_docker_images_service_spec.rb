# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Integrations::GoogleCloudPlatform::ArtifactRegistry::ListDockerImagesService, feature_category: :container_registry do
  let_it_be(:project) { create(:project, :private) }

  let(:user) { project.owner }
  let(:gcp_project_id) { 'gcp_project_id' }
  let(:gcp_location) { 'gcp_location' }
  let(:gcp_repository) { 'gcp_repository' }
  let(:gcp_wlif) { 'https://wlif.test' }
  let(:service) do
    described_class.new(
      project: project,
      current_user: user,
      params: {
        gcp_project_id: gcp_project_id,
        gcp_location: gcp_location,
        gcp_repository: gcp_repository,
        gcp_wlif: gcp_wlif
      }
    )
  end

  describe '#execute' do
    let(:page_token) { nil }
    let(:list_docker_images_response) { dummy_list_response }
    let(:client_double) { instance_double('::Integrations::GoogleCloudPlatform::ArtifactRegistry::Client') }

    before do
      allow(::Integrations::GoogleCloudPlatform::ArtifactRegistry::Client).to receive(:new)
        .with(
          project: project,
          user: user,
          gcp_project_id: gcp_project_id,
          gcp_location: gcp_location,
          gcp_repository: gcp_repository,
          gcp_wlif: gcp_wlif
        ).and_return(client_double)
      allow(client_double).to receive(:list_docker_images)
        .with(page_token: page_token)
        .and_return(list_docker_images_response)
    end

    subject(:list) { service.execute(page_token: page_token) }

    it 'returns the docker images' do
      expect(list).to be_success
      expect(list.payload).to include(images: an_instance_of(Array), next_page_token: an_instance_of(String))
    end

    context 'with the client returning an empty hash' do
      let(:list_docker_images_response) { {} }

      it 'returns an empty hash' do
        expect(list).to be_success
        expect(list.payload).to eq({})
      end
    end

    context 'with not enough permissions' do
      let_it_be(:user) { create(:user) }

      it 'returns an error response' do
        expect(list).to be_error
        expect(list.message).to eq('Access denied')
      end
    end

    private

    def dummy_list_response
      {
        images: [
          {
            built_at: '2023-11-30T23:23:11.980068941Z',
            media_type: 'application/vnd.docker.distribution.manifest.v2+json',
            name: 'projects/project/locations/location/repositories/repo/dockerImages/image@sha256:6a',
            size_bytes: 2827903,
            tags: %w[tag1 tag2],
            updated_at: '2023-12-07T11:48:50.840751Z',
            uploaded_at: '2023-12-07T11:48:47.598511Z',
            uri: 'location.pkg.dev/project/repo/image@sha256:6a'
          }
        ],
        next_page_token: 'next_page_token'
      }
    end
  end
end
