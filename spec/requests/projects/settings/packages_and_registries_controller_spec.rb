# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::PackagesAndRegistriesController, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, namespace: user.namespace) }

  let(:container_registry_enabled) { true }
  let(:container_registry_enabled_on_project) { ProjectFeature::ENABLED }

  before do
    project.project_feature.update!(container_registry_access_level: container_registry_enabled_on_project)
    project.container_expiration_policy.update!(enabled: true)

    stub_container_registry_config(enabled: container_registry_enabled)
  end

  shared_examples 'pushed feature flag' do |feature_flag_name|
    let(:feature_flag_name_camelized) { feature_flag_name.to_s.camelize(:lower).to_sym }

    it "pushes feature flag :#{feature_flag_name} to the view" do
      subject

      expect(response.body).to have_pushed_frontend_feature_flags(feature_flag_name_camelized => true)
    end

    context "when feature flag :#{feature_flag_name} is disabled" do
      before do
        stub_feature_flags(feature_flag_name.to_sym => false)
      end

      it "does not push feature flag :#{feature_flag_name} to the view" do
        subject

        expect(response.body).to have_pushed_frontend_feature_flags(feature_flag_name_camelized => false)
      end
    end
  end

  describe 'GET #show' do
    context 'when user is authorized' do
      let(:user) { project.creator }

      subject { get namespace_project_settings_packages_and_registries_path(user.namespace, project) }

      before do
        sign_in(user)
        allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
      end

      it_behaves_like 'pushed feature flag', :packages_protected_packages
      it_behaves_like 'pushed feature flag', :packages_protected_packages_pypi
      it_behaves_like 'pushed feature flag', :container_registry_protected_containers
    end
  end

  describe 'GET #cleanup_tags' do
    subject { get cleanup_image_tags_namespace_project_settings_packages_and_registries_path(user.namespace, project) }

    context 'when user is unauthorized' do
      let_it_be(:user) { create(:user) }

      before do
        project.add_reporter(user)
        sign_in(user)
        subject
      end

      it 'shows 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is authorized' do
      let(:user) { project.creator }

      before do
        sign_in(user)
        subject
      end

      it 'renders content' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:cleanup_tags)
      end

      context 'when registry is disabled' do
        let(:container_registry_enabled) { false }

        it 'shows 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when container registry is disabled on project' do
        let(:container_registry_enabled_on_project) { ProjectFeature::DISABLED }

        it 'shows 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
