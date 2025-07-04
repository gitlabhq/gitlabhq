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
      end

      context 'with incorrect permissons' do
        let(:user) { create(:user) }

        before do
          group.add_developer(user)
          sign_in(user)
        end

        subject { get group_observability_path(group, 'services') }

        it_behaves_like 'redirects to 404'
      end

      context 'when the ENV var is not set' do
        subject(:services_page) { get group_observability_path(group, 'services') }

        before do
          stub_env('O11Y_URL', 'http://localhost:3301/')
        end

        it 'sets the o11y url' do
          services_page
          expect(response).to render_template(:show)
          expect(assigns(:path)).to eq('services')
          expect(assigns(:o11y_url)).to eq('http://localhost:3301/')
        end
      end

      context 'with a valid path parameter' do
        Groups::ObservabilityController::VALID_PATHS.each do |path|
          context "with path=#{path}" do
            subject(:observability_page) { get group_observability_path(group, path) }

            it 'renders the observability page with the specified path' do
              observability_page

              expect(response).to have_gitlab_http_status(:ok)
              expect(assigns(:path)).to eq(path)
            end
          end
        end
      end

      context 'with an invalid path parameter' do
        subject { get group_observability_path(group, 'invalid-path') }

        it_behaves_like 'redirects to 404'
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
    subject(:csp_header) { response.headers['Content-Security-Policy'] }

    before do
      stub_feature_flags(observability_sass_features: group)
    end

    context 'when O11Y_URL environment variable is set' do
      let(:o11y_url) { 'https://observability.example.com' }

      before do
        stub_env('O11Y_URL', o11y_url)
      end

      context 'when CSP directives are present' do
        let(:csp) do
          ActionDispatch::ContentSecurityPolicy.new do |p|
            p.frame_src "'self'", 'https://existing-frame.example.com'
          end
        end

        before do
          stub_csp_for_controller(described_class, csp)
          get group_observability_path(group, 'services')
        end

        it 'adds O11Y_URL to frame-src directive' do
          frame_src_values = find_csp_directive('frame-src', header: csp_header)
          expect(frame_src_values).to include("'self'", 'https://existing-frame.example.com', o11y_url)
        end
      end

      context 'when CSP frame-src directive is not present' do
        let(:csp) do
          ActionDispatch::ContentSecurityPolicy.new do |p|
            p.script_src "'self'"
          end
        end

        before do
          stub_csp_for_controller(described_class, csp)
          get group_observability_path(group, 'services')
        end

        it 'creates frame-src directive with O11Y_URL' do
          frame_src_values = find_csp_directive('frame-src', header: csp_header)
          expect(frame_src_values).to include("'self'", o11y_url)
        end
      end

      context 'when CSP has no directives' do
        let(:csp) { ActionDispatch::ContentSecurityPolicy.new }

        before do
          stub_csp_for_controller(described_class, csp)
          get group_observability_path(group, 'services')
        end

        it 'does not add frame-src directive' do
          expect(csp_header).to be_blank
        end
      end
    end

    context 'when O11Y_URL environment variable is not set' do
      before do
        stub_env('O11Y_URL', nil)
      end

      context 'when CSP directives are present' do
        let(:csp) do
          ActionDispatch::ContentSecurityPolicy.new do |p|
            p.frame_src "'self'", 'https://existing-frame.example.com'
          end
        end

        before do
          stub_csp_for_controller(described_class, csp)
          get group_observability_path(group, 'services')
        end

        it 'does not modify frame-src directive' do
          frame_src_values = find_csp_directive('frame-src', header: csp_header)
          expect(frame_src_values).to contain_exactly("'self'", 'https://existing-frame.example.com')
        end
      end

      context 'when CSP has no directives' do
        let(:csp) { ActionDispatch::ContentSecurityPolicy.new }

        before do
          stub_csp_for_controller(described_class, csp)
          get group_observability_path(group, 'services')
        end

        it 'does not add frame-src directive' do
          expect(csp_header).to be_blank
        end
      end
    end

    context 'when O11Y_URL environment variable is empty string' do
      before do
        stub_env('O11Y_URL', '')
      end

      context 'when CSP directives are present' do
        let(:csp) do
          ActionDispatch::ContentSecurityPolicy.new do |p|
            p.frame_src "'self'", 'https://existing-frame.example.com'
          end
        end

        before do
          stub_csp_for_controller(described_class, csp)
          get group_observability_path(group, 'services')
        end

        it 'does not modify frame-src directive' do
          frame_src_values = find_csp_directive('frame-src', header: csp_header)
          expect(frame_src_values).to contain_exactly("'self'", 'https://existing-frame.example.com')
        end
      end
    end

    context 'when CSP directives are blank' do
      let(:csp) { ActionDispatch::ContentSecurityPolicy.new }

      before do
        stub_env('O11Y_URL', 'https://observability.example.com')
        stub_csp_for_controller(described_class, csp)
        get group_observability_path(group, 'services')
      end

      it 'does not add frame-src directive' do
        expect(csp_header).to be_blank
      end
    end
  end
end
