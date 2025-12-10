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
    subject(:observability_page) { get group_observability_path(group, '') }

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: group)
        allow(Observability::O11yToken).to receive(:generate_tokens).and_return({ 'testToken' => 'value' })
      end

      context 'with incorrect permissions' do
        let(:user) { create(:user) }

        before do
          group.add_guest(user)
          sign_in(user)
        end

        subject { get group_observability_path(group, 'services') }

        it_behaves_like 'redirects to 404'
      end

      context 'when the group has observability settings' do
        subject(:services_page) { get group_observability_path(group, 'services') }

        let!(:observability_setting) do
          create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://observability.example.com')
        end

        it 'sets the o11y url from group settings' do
          services_page
          expect(response).to render_template(:show)
          expect(assigns(:data)).to be_a(Observability::ObservabilityPresenter)
          expect(assigns(:data).to_h[:path]).to eq('services')
          expect(assigns(:data).to_h[:o11y_url]).to eq('https://observability.example.com')
        end
      end

      context 'when the group has no observability settings' do
        subject(:services_page) { get group_observability_path(group, 'services') }

        it 'sets the o11y url to nil' do
          services_page
          expect(response).to render_template(:show)
          expect(assigns(:data)).to be_a(Observability::ObservabilityPresenter)
          expect(assigns(:data).to_h[:path]).to eq('services')
          expect(assigns(:data).to_h[:o11y_url]).to be_nil
        end
      end

      context 'with a valid path parameter' do
        let!(:observability_setting) do
          create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://o11y.gitlab.com')
        end

        Groups::ObservabilityController::VALID_PATHS.each do |path|
          context "with path=#{path}" do
            subject(:observability_page) { get group_observability_path(group, path) }

            it 'renders the observability page with the specified path' do
              observability_page

              expect(response).to have_gitlab_http_status(:ok)
              expect(assigns(:data)).to be_a(Observability::ObservabilityPresenter)
              expect(assigns(:data).to_h[:path]).to eq(path)
              expect(assigns(:data).to_h[:o11y_url]).to eq('https://o11y.gitlab.com')
              expect(assigns(:data).title).to eq(Observability::ObservabilityPresenter::PATHS.fetch(path,
                'Observability'))
              expect(assigns(:data).auth_tokens).to eq({ 'test_token' => 'value' })
            end
          end
        end
      end

      context 'with JSON format' do
        let!(:observability_setting) do
          create(:observability_group_o11y_setting, group: group, o11y_service_url: 'https://observability.example.com')
        end

        context 'when JSON is requested' do
          subject(:get_json) { get group_observability_path(group, 'services', format: :json) }

          it 'returns JSON response' do
            get_json

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.content_type).to include('application/json')
          end

          it 'returns the correct JSON structure' do
            get_json

            expect(json_response).to include(
              'o11y_url' => 'https://observability.example.com',
              'path' => 'services',
              'title' => 'Observability|Services'
            )
            expect(json_response).to have_key('auth_tokens')
            expect(json_response['auth_tokens']).to eq({ 'test_token' => 'value' })
          end
        end

        context 'when group has no observability settings' do
          let!(:observability_setting) { nil }

          subject(:get_json) { get group_observability_path(group, 'services', format: :json) }

          it 'returns JSON with nil o11y_url' do
            get_json

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to include(
              'o11y_url' => nil,
              'path' => 'services',
              'title' => 'Observability|Services'
            )
          end
        end

        context 'with different valid paths' do
          Groups::ObservabilityController::VALID_PATHS.each do |path|
            context "with path=#{path}" do
              subject(:get_json) { get group_observability_path(group, path, format: :json) }

              it 'returns JSON with correct path and title' do
                get_json

                expect(response).to have_gitlab_http_status(:ok)
                expect(json_response['path']).to eq(path)
                expect(json_response['title']).to eq(Observability::ObservabilityPresenter::PATHS.fetch(path,
                  'Observability'))
              end
            end
          end
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
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(observability_sass_features: false)
      end

      it_behaves_like 'redirects to 404'
    end

    context 'when user is not authenticated' do
      before do
        stub_feature_flags(observability_sass_features: group)
        sign_out(user)
      end

      it 'redirects to sign in page' do
        observability_page

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'Content Security Policy' do
    let(:csp_header) { response.headers['Content-Security-Policy'] }
    let(:frame_src_values) { find_csp_directive('frame-src', header: csp_header) }

    before do
      stub_feature_flags(observability_sass_features: group)
    end

    shared_examples 'includes o11y url in frame-src' do |o11y_url|
      it "includes '#{o11y_url}' in frame-src directive" do
        expect(frame_src_values).to include("'self'", o11y_url)
      end
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
