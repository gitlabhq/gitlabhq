# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ObservabilityController, feature_category: :tracing do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:observability_url) { Gitlab::Observability.observability_url }
  let(:path) { nil }
  let(:expected_observability_path) { nil }

  shared_examples 'observability route request' do
    subject do
      get path
      response
    end

    it_behaves_like 'observability csp policy' do
      let(:tested_path) { path }
    end

    context 'when user is not authenticated' do
      it 'returns 404' do
        expect(subject).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is a guest' do
      before do
        sign_in(user)
      end

      it 'returns 404' do
        expect(subject).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user has the correct permissions' do
      before do
        sign_in(user)
        set_permissions
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
        expect(subject).to render_template("groups/observability/observability")
      end

      it 'renders the js-observability-app element correctly' do
        element = Nokogiri::HTML.parse(subject.body).at_css('#js-observability-app')
        expect(element.attributes['data-observability-iframe-src'].value).to eq(expected_observability_path)
      end
    end
  end

  describe 'GET #explore' do
    let(:path) { group_observability_explore_path(group) }
    let(:expected_observability_path) { "#{observability_url}/-/#{group.id}/explore" }

    it_behaves_like 'observability route request' do
      let(:set_permissions) do
        group.add_developer(user)
      end
    end
  end

  describe 'GET #datasources' do
    let(:path) { group_observability_datasources_path(group) }
    let(:expected_observability_path) { "#{observability_url}/-/#{group.id}/datasources" }

    it_behaves_like 'observability route request' do
      let(:set_permissions) do
        group.add_maintainer(user)
      end
    end
  end
end
