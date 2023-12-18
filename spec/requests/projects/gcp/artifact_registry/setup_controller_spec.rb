# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Gcp::ArtifactRegistry::SetupController, feature_category: :container_registry do
  let_it_be(:project) { create(:project, :private) }

  let(:user) { project.owner }

  describe '#new' do
    subject(:get_setup_page) { get(new_project_gcp_artifact_registry_setup_path(project)) }

    shared_examples 'returning the error message' do |message|
      it 'displays an error message' do
        sign_in(user)

        get_setup_page

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).to include(message)
      end
    end

    context 'when on saas', :saas do
      it 'returns the setup page' do
        sign_in(user)

        get_setup_page

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).to include('Google Project ID')
        expect(response.body).to include('Google Project Location')
        expect(response.body).to include('Artifact Registry Repository Name')
        expect(response.body).to include('Worflow Identity Federation url')
        expect(response.body).to include('Setup')
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

          get_setup_page

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when not on saas' do
      it_behaves_like 'returning the error message', "Can&#39;t run here"
    end
  end
end
