# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ObservabilityController, feature_category: :observability do
  include ContentSecurityPolicyHelpers

  let(:group) { create(:group, :public) }
  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  shared_examples 'redirects to 404' do
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET #show' do
    subject(:observability_page) { get group_observability_path(group, 'alerts') }

    before do
      stub_feature_flags(observability_sass_features: group)
      allow(Observability::O11yToken).to receive(:generate_tokens).and_return({ 'testToken' => 'value' })
      allow_next_instance_of(Observability::ObservabilityPresenter) do |instance|
        allow(instance).to receive(:auth_tokens).and_return({ 'test_token' => 'value' })
      end
    end

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

    context 'when the group has observability settings' do
      let!(:observability_setting) do
        create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://observability.example.com')
      end

      subject(:services_page) { get group_observability_path(group, 'services') }

      it 'renders the show template and exposes a presenter with the group o11y url' do
        services_page

        expect(response).to render_template(:show)
        expect(assigns(:data)).to be_a(Observability::ObservabilityPresenter)
        expect(assigns(:data).to_h).to include(
          path: 'services',
          o11y_url: 'https://observability.example.com'
        )
      end

      context 'when checking iframe partial markup' do
        before do
          services_page
        end

        it_behaves_like 'renders observability iframe'
      end
    end

    context 'when the group has no observability settings' do
      subject(:services_page) { get group_observability_path(group, 'services') }

      it 'renders the show template with a nil o11y url' do
        services_page

        expect(response).to render_template(:show)
        expect(assigns(:data).to_h).to include(path: 'services', o11y_url: nil)
      end
    end

    context 'with an invalid path parameter' do
      context 'with HTML format' do
        subject { get group_observability_path(group, 'invalid-path') }

        it_behaves_like 'redirects to 404'
      end

      context 'with JSON format' do
        subject { get group_observability_path(group, 'invalid-path', format: :json) }

        it_behaves_like 'redirects to 404'
      end
    end

    context 'with JSON format' do
      let!(:observability_setting) do
        create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://observability.example.com')
      end

      subject(:get_json) { get group_observability_path(group, 'services', format: :json) }

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

      context 'when group has no observability settings' do
        let!(:observability_setting) { nil }

        it 'returns JSON with nil o11y_url' do
          get_json

          expect(json_response).to include('o11y_url' => nil, 'path' => 'services')
        end
      end
    end

    context 'with sub-path routing' do
      # One representative per distinct routing shape: single-segment, two-segment static,
      # two-segment parametric, three-segment static, three-segment parametric.
      # Title inheritance and full path coverage are the presenter's responsibility.
      {
        'alerts' => 'Observability|Alerts',
        'alerts/edit' => 'Observability|Alerts',
        'dashboard/my-dashboard' => 'Observability|Dashboard',
        'messaging-queues/kafka/detail' => 'Observability|Messaging queues',
        'services/my-service/top-level-operations' => 'Observability|Services'
      }.each do |sub_path, expected_title|
        it "routes #{sub_path} to the controller and resolves the correct title" do
          get group_observability_path(group, sub_path)

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:data).title).to eq(expected_title)
          expect(assigns(:data).to_h[:path]).to eq(sub_path)
        end
      end

      context 'with bare top-level-only prefixes (sub-path required)' do
        where(:bare_path) do
          ['infrastructure-monitoring']
        end

        with_them do
          it 'returns 404' do
            get group_observability_path(group, bare_path)

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
            get "/groups/#{group.full_path}/-/observability/#{url_suffix}"

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
          get group_observability_path(group, 'alerts')

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with query parameter forwarding' do
      it 'forwards allowed params and strips disallowed ones' do
        get group_observability_path(group, 'alerts', ruleId: 'abc-123', evil: 'bad', tab: 'overview')

        expect(assigns(:data).to_h[:query_params]).to eq({ 'ruleId' => 'abc-123', 'tab' => 'overview' })
      end

      it 'drops all params when the query string exceeds 10000 bytes' do
        get group_observability_path(group, 'alerts', ruleId: 'abc-123', search: 'x' * 10_001)

        expect(assigns(:data).to_h[:query_params]).to eq({})
      end

      it 'includes query_params in the JSON response' do
        get group_observability_path(group, 'alerts', format: :json, ruleId: 'abc-123', tab: 'overview')

        expect(json_response['query_params']).to eq({ 'ruleId' => 'abc-123', 'tab' => 'overview' })
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
        get group_path(group)
        find_csp_directive('frame-src', header: response.headers['Content-Security-Policy'])
      end

      it 'does not modify frame-src directive' do
        expect(frame_src_values).to match_array(baseline_frame_src_values)
      end
    end

    context 'when group has no observability settings' do
      before do
        get group_observability_path(group, 'services')
      end

      it_behaves_like 'does not modify frame-src directive'
    end

    context 'when switching between groups with different observability settings' do
      let(:group_with_different_o11y) { create(:group, :public) }
      let(:o11y_url) { 'https://observability.example.com' }
      let(:o11y_url_2) { 'https://observability.example.com/2' }

      before do
        group_with_different_o11y.add_maintainer(user)
        stub_feature_flags(observability_sass_features: group_with_different_o11y)
        create(:observability_group_o11y_setting, group: group_with_different_o11y, o11y_service_url: o11y_url_2)
        allow(Observability::O11yToken).to receive(:generate_tokens).and_return({ 'testToken' => 'value' })

        get group_observability_path(group_with_different_o11y, 'services')
      end

      it 'adds o11y_service_url to frame-src directive' do
        frame_src_values = find_csp_directive('frame-src', header: csp_header)
        expect(frame_src_values).to include("'self'", o11y_url_2)

        get group_observability_path(group, 'services')

        frame_src_values = find_csp_directive('frame-src', header: csp_header)
        expect(frame_src_values).not_to include(o11y_url)
        expect(frame_src_values).to include("'self'", o11y_url_2)
      end
    end
  end
end
