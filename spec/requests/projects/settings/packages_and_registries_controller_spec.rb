# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::PackagesAndRegistriesController, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, namespace: user.namespace) }
  let_it_be(:maintainer) { create(:user) }

  let(:container_registry_enabled) { true }
  let(:container_registry_enabled_on_project) { ProjectFeature::ENABLED }

  before do
    project.project_feature.update!(container_registry_access_level: container_registry_enabled_on_project)
    project.container_expiration_policy.update!(enabled: true)

    stub_container_registry_config(enabled: container_registry_enabled)
  end

  describe 'GET #show' do
    subject { get namespace_project_settings_packages_and_registries_path(user.namespace, project) }

    before do
      allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
    end

    context 'when user is authorized' do
      let(:user) { project.creator }

      before do
        sign_in(user)
      end

      it_behaves_like 'pushed feature flag', :packages_protected_packages_helm
      it_behaves_like 'pushed feature flag', :packages_protected_packages_nuget
      it_behaves_like 'pushed feature flag', :packages_protected_packages_delete
      it_behaves_like 'pushed feature flag', :packages_protected_packages_generic
      it_behaves_like 'pushed feature flag', :container_registry_protected_containers_delete
      it_behaves_like 'pushed feature flag', :container_registry_immutable_tags
    end

    context 'when createContainerRegistryProtectionImmutableTagRule ability is allowed' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :create_container_registry_protection_immutable_tag_rule, project)
          .and_return(true)
        sign_in(user)
      end

      it 'sets the frontend ability to true' do
        subject

        expect(response.body).to have_pushed_frontend_ability(createContainerRegistryProtectionImmutableTagRule: true)
      end
    end

    context 'when createContainerRegistryProtectionImmutableTagRule ability is not allowed' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :create_container_registry_protection_immutable_tag_rule, project)
          .and_return(false)
        sign_in(user)
      end

      it 'sets the frontend ability to false' do
        subject

        expect(response.body).to have_pushed_frontend_ability(createContainerRegistryProtectionImmutableTagRule: false)
      end
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
