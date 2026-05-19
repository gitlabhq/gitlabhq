# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ObservabilityController, feature_category: :observability do
  include ContentSecurityPolicyHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:user) { create(:user) }

  before_all do
    group.add_maintainer(user)
  end

  before do
    sign_in(user)
    stub_feature_flags(observability_sass_features: group)
    allow(Observability::O11yToken).to receive(:generate_tokens).and_return({ 'testToken' => 'value' })
    allow_next_instance_of(Observability::ObservabilityPresenter) do |instance|
      allow(instance).to receive(:auth_tokens).and_return({ 'test_token' => 'value' })
    end
  end

  shared_examples 'redirects to 404' do
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET #show' do
    subject(:observability_page) { get project_observability_path(project, 'alerts') }

    it_behaves_like 'observability requires feature flag'
    it_behaves_like 'observability requires permissions'

    context 'when user is not authenticated' do
      before do
        sign_out(user)
      end

      it 'redirects to sign in page' do
        observability_page

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when an ancestor group has an observability setting' do
      let!(:observability_setting) do
        create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://observability.example.com')
      end

      subject(:services_page) { get project_observability_path(project, 'services') }

      it 'renders the iframe container markup with the o11y url' do
        services_page

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('js-observability')
        expect(response.body).to include('observability-container')
      end

      it 'exposes the correct o11y url and path via JSON' do
        get project_observability_path(project, 'services', format: :json)

        expect(json_response).to include(
          'path' => 'services',
          'o11y_url' => 'https://observability.example.com'
        )
      end

      context 'when checking iframe partial markup' do
        before do
          services_page
        end

        it_behaves_like 'renders observability iframe'
      end
    end

    context 'when no ancestor group has an observability setting' do
      subject(:services_page) { get project_observability_path(project, 'services') }

      it 'redirects to the group observability setup page' do
        services_page

        expect(response).to redirect_to(group_observability_setup_path(group))
      end
    end

    context 'when project belongs to a personal namespace' do
      it 'returns 404' do
        personal_project = create(:project, :public, :in_user_namespace)
        get project_observability_path(personal_project, 'alerts')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an invalid path parameter' do
      where(:format) { [:html, :json] }

      with_them do
        subject { get project_observability_path(project, 'invalid-path', format: format) }

        it_behaves_like 'redirects to 404'
      end
    end

    context 'with JSON format' do
      let!(:observability_setting) do
        create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://observability.example.com')
      end

      subject(:get_json) do
        get project_observability_path(project, 'services', format: :json)
      end

      it 'returns the full JSON structure' do
        get_json

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.content_type).to include('application/json')
        expect(json_response).to include(
          'o11y_url' => 'https://observability.example.com',
          'path' => 'services',
          'title' => 'Observability|Services',
          'query_params' => {}
        )
        expect(json_response).to have_key('auth_tokens')
        expect(json_response['auth_tokens']).to eq({ 'test_token' => 'value' })
      end

      context 'when no ancestor has an observability setting' do
        let!(:observability_setting) { nil }

        it 'redirects to the group observability setup page' do
          get_json

          expect(response).to redirect_to(group_observability_setup_path(group))
        end
      end
    end

    context 'with sub-path routing' do
      let!(:observability_setting) do
        create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://observability.example.com')
      end

      {
        'alerts' => 'Observability|Alerts',
        'alerts/edit' => 'Observability|Alerts',
        'dashboard/my-dashboard' => 'Observability|Dashboard',
        'messaging-queues/kafka/detail' => 'Observability|Messaging queues',
        'services/my-service/top-level-operations' => 'Observability|Services'
      }.each do |sub_path, expected_title|
        it "routes #{sub_path} to the controller and resolves the correct title" do
          path = if sub_path.include?('/')
                   project_observability_sub_path_path(project, sub_path, format: :json)
                 else
                   project_observability_path(project, sub_path, format: :json)
                 end

          get path

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['title']).to eq(expected_title)
          expect(json_response['path']).to eq(sub_path)
        end
      end

      context 'with bare top-level-only prefixes (sub-path required)' do
        where(:bare_path) do
          ['infrastructure-monitoring']
        end

        with_them do
          it 'returns 404' do
            get project_observability_path(project, bare_path)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'with path traversal attempts' do
        where(:url_suffix) do
          [
            ['alerts/../admin'],
            ['alerts/%2e%2e/admin'],
            ['alerts/%252e%252e/admin'],
            ['..%2Fadmin']
          ]
        end

        with_them do
          it 'returns 400 or 404' do
            get "/#{project.full_path}/-/observability/#{url_suffix}"

            expect(response.status).to be_in([400, 404])
          end
        end
      end

      context 'when path traversal is detected by the controller' do
        before do
          allow(Gitlab::PathTraversal).to receive(:check_path_traversal!)
            .and_raise(Gitlab::PathTraversal::PathTraversalAttackError)
        end

        it 'returns 404' do
          get project_observability_path(project, 'alerts')

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with query parameter forwarding' do
      let!(:observability_setting) do
        create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://observability.example.com')
      end

      it 'forwards allowed params and strips disallowed ones' do
        get project_observability_path(project, 'alerts', format: :json, ruleId: 'abc-123', evil: 'bad',
          tab: 'overview')

        expect(json_response['query_params']).to eq({ 'ruleId' => 'abc-123', 'tab' => 'overview' })
      end

      it 'drops all params when the query string exceeds the max bytes limit' do
        get project_observability_path(project, 'alerts', format: :json, ruleId: 'abc-123',
          search: 'x' * 10_001)

        expect(json_response['query_params']).to eq({})
      end
    end
  end

  describe 'Content Security Policy' do
    let(:csp_header) { response.headers['Content-Security-Policy'] }
    let(:frame_src_values) { find_csp_directive('frame-src', header: csp_header) }

    before do
      stub_feature_flags(observability_sass_features: group)
    end

    shared_examples 'does not modify frame-src directive' do
      let(:baseline_frame_src_values) do
        get project_path(project)
        find_csp_directive('frame-src', header: response.headers['Content-Security-Policy'])
      end

      it 'does not modify frame-src directive' do
        expect(frame_src_values).to match_array(baseline_frame_src_values)
      end
    end

    context 'when no ancestor has an observability setting' do
      it 'redirects to the group observability setup page' do
        get project_observability_path(project, 'services')

        expect(response).to redirect_to(group_observability_setup_path(group))
      end
    end

    context 'when an ancestor group has an observability setting' do
      let(:o11y_url) { 'https://observability.example.com' }

      before do
        create(:observability_group_o11y_setting, group: group, o11y_service_url: o11y_url)
        allow(Observability::O11yToken).to receive(:generate_tokens).and_return({ 'testToken' => 'value' })

        get project_observability_path(project, 'services')
      end

      it 'adds the o11y_service_url to the frame-src directive' do
        expect(frame_src_values).to include("'self'", o11y_url)
      end
    end
  end
end
