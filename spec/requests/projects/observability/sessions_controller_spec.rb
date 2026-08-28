# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Observability::SessionsController, feature_category: :observability do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:user) { create(:user) }

  let!(:observability_setting) do
    create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://o11y.example.com')
  end

  before_all do
    # read_observability_portal is a group-scoped permission (see
    # config/authz/roles/developer.yml), so the user needs group membership,
    # not just project membership, to reach this controller.
    group.add_maintainer(user)
  end

  before do
    sign_in(user)
    stub_feature_flags(observability_sass_features: group, observability_per_user_bff_auth: group)
  end

  describe 'POST #create' do
    subject(:make_request) { post project_observability_session_path(project) }

    it_behaves_like 'observability BFF session actions'
  end

  context 'when project belongs to a personal namespace' do
    let_it_be(:personal_project) { create(:project, :public, :in_user_namespace) }
    let_it_be(:owner) { personal_project.first_owner }

    let!(:personal_observability_setting) do
      create(:observability_group_o11y_setting, group: personal_project.namespace,
        o11y_service_url: 'https://o11y.example.com')
    end

    subject(:make_request) { post project_observability_session_path(personal_project) }

    before do
      sign_in(owner)
      stub_feature_flags(
        observability_saas_features_user_namespace: personal_project.root_namespace,
        observability_per_user_bff_auth: personal_project.root_namespace
      )
      allow(::Observability::O11yBffSession).to receive(:generate_tokens)
        .and_return({ accessJwt: 'a-jwt', refreshJwt: 'r-jwt' })
    end

    it 'returns the per-user tokens as JSON' do
      make_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(
        'auth_tokens' => { 'access_jwt' => 'a-jwt', 'refresh_jwt' => 'r-jwt' }
      )
    end

    context 'when the observability_saas_features_user_namespace flag is disabled' do
      before do
        stub_feature_flags(observability_saas_features_user_namespace: false)
      end

      it 'returns 404' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the BFF flag is enabled only for a different namespace' do
      let_it_be(:other_namespace) { create(:group) }

      before do
        # The flag actor for a personal-namespace project is
        # project.root_namespace -- enabling the flag for an unrelated
        # namespace must not enable it here. Guards against the flag
        # check receiving a nil actor, which Flipper evaluates globally.
        stub_feature_flags(observability_per_user_bff_auth: other_namespace)
      end

      it 'returns 404' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
