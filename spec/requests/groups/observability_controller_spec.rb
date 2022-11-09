# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ObservabilityController do
  include ContentSecurityPolicyHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:observability_url) { Gitlab::Observability.observability_url }

  subject do
    get group_observability_index_path(group)
    response
  end

  describe 'GET #index' do
    context 'when user is not authenticated' do
      it 'returns 404' do
        expect(subject).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not a developer' do
      before do
        sign_in(user)
      end

      it 'returns 404' do
        expect(subject).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is authenticated and a developer' do
      before do
        sign_in(user)
        group.add_developer(user)
      end

      context 'when observability url is missing' do
        before do
          allow(Gitlab::Observability).to receive(:observability_url).and_return("")
        end

        it 'returns 404' do
          expect(subject).to have_gitlab_http_status(:not_found)
        end
      end

      it 'returns 200' do
        expect(subject).to have_gitlab_http_status(:ok)
      end

      it 'renders the proper layout' do
        expect(subject).to render_template("layouts/group")
        expect(subject).to render_template("layouts/fullscreen")
        expect(subject).not_to render_template('layouts/nav/breadcrumbs')
        expect(subject).to render_template("nav/sidebar/_group")
      end

      describe 'iframe' do
        subject do
          get group_observability_index_path(group)
          Nokogiri::HTML.parse(response.body).at_css('iframe#observability-ui-iframe')
        end

        it 'sets the iframe src to the proper URL' do
          expected_url = "#{observability_url}/-/#{group.id}"

          expect(subject.attributes['src'].value).to eq(expected_url)
        end
      end

      describe 'CSP' do
        before do
          setup_csp_for_controller(described_class, csp)
        end

        subject do
          get group_observability_index_path(group)
          response.headers['Content-Security-Policy']
        end

        context 'when there is no CSP config' do
          let(:csp) { ActionDispatch::ContentSecurityPolicy.new }

          it 'does not add any csp header' do
            expect(subject).to be_blank
          end
        end

        context 'when frame-src exists in the CSP config' do
          let(:csp) do
            ActionDispatch::ContentSecurityPolicy.new do |p|
              p.frame_src 'https://something.test'
            end
          end

          it 'appends the proper url to frame-src CSP directives' do
            expect(subject).to include(
              "frame-src https://something.test #{observability_url} 'self'")
          end
        end

        context 'when self is already present in the policy' do
          let(:csp) do
            ActionDispatch::ContentSecurityPolicy.new do |p|
              p.frame_src "'self'"
            end
          end

          it 'does not append self again' do
            expect(subject).to include(
              "frame-src 'self' #{observability_url};")
          end
        end

        context 'when default-src exists in the CSP config' do
          let(:csp) do
            ActionDispatch::ContentSecurityPolicy.new do |p|
              p.default_src 'https://something.test'
            end
          end

          it 'does not change default-src' do
            expect(subject).to include(
              "default-src https://something.test;")
          end

          it 'appends the proper url to frame-src CSP directives' do
            expect(subject).to include(
              "frame-src https://something.test #{observability_url} 'self'")
          end
        end

        context 'when frame-src and default-src exist in the CSP config' do
          let(:csp) do
            ActionDispatch::ContentSecurityPolicy.new do |p|
              p.default_src 'https://something_default.test'
              p.frame_src 'https://something.test'
            end
          end

          it 'appends to frame-src CSP directives' do
            expect(subject).to include(
              "frame-src https://something.test #{observability_url} 'self'")
            expect(subject).to include(
              "default-src https://something_default.test")
          end
        end
      end
    end
  end
end
