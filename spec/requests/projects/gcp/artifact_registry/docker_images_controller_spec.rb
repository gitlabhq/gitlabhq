# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Gcp::ArtifactRegistry::DockerImagesController, feature_category: :container_registry do
  let_it_be(:project) { create(:project, :private) }

  let(:user) { project.owner }
  let(:gcp_project_id) { 'gcp_project_id' }
  let(:gcp_location) { 'gcp_location' }
  let(:gcp_ar_repository) { 'gcp_ar_repository' }
  let(:gcp_wlif_url) { 'gcp_wlif_url' }

  describe '#index' do
    let(:service_response) { ServiceResponse.success(payload: dummy_client_payload) }
    let(:service_double) do
      instance_double('Integrations::GoogleCloudPlatform::ArtifactRegistry::ListDockerImagesService')
    end

    subject(:get_index_page) do
      get(
        project_gcp_artifact_registry_docker_images_path(
          project,
          gcp_project_id: gcp_project_id,
          gcp_location: gcp_location,
          gcp_ar_repository: gcp_ar_repository,
          gcp_wlif_url: gcp_wlif_url
        )
      )
    end

    before do
      allow_next_instance_of(Integrations::GoogleCloudPlatform::ArtifactRegistry::ListDockerImagesService) do |service|
        allow(service).to receive(:execute).and_return(service_response)
      end
    end

    shared_examples 'returning the error message' do |message|
      it 'displays an error message' do
        sign_in(user)

        get_index_page

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).to include(message)
      end
    end

    context 'when on saas', :saas do
      it 'returns the images' do
        sign_in(user)

        get_index_page

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).to include('image@sha256:6a')
        expect(response.body).to include('tag1')
        expect(response.body).to include('tag2')
        expect(response.body).to include('Prev')
        expect(response.body).to include('Next')
      end

      context 'when the service returns an error response' do
        let(:service_response) { ServiceResponse.error(message: 'boom') }

        it_behaves_like 'returning the error message', 'boom'
      end

      %i[gcp_project_id gcp_location gcp_ar_repository gcp_wlif_url].each do |field|
        context "when a gcp parameter #{field} is missing" do
          let(field) { nil }

          it 'redirects to setup page' do
            sign_in(user)

            get_index_page

            expect(response).to redirect_to new_project_gcp_artifact_registry_setup_path(project)
          end
        end
      end

      context 'with the feature flag disabled' do
        before do
          stub_feature_flags(gcp_technical_demo: false)
        end

        it_behaves_like 'returning the error message', 'Feature flag disabled'
      end

      context 'with non private project' do
        before do
          allow_next_found_instance_of(Project) do |project|
            allow(project).to receive(:private?).and_return(false)
          end
        end

        it_behaves_like 'returning the error message', 'Can only run on private projects'
      end

      context 'with unauthorized user' do
        let_it_be(:user) { create(:user) }

        it 'returns success' do
          sign_in(user)

          get_index_page

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when not on saas' do
      it_behaves_like 'returning the error message', "Can&#39;t run here"
    end

    def dummy_client_payload
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
