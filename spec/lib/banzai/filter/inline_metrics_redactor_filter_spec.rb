# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::InlineMetricsRedactorFilter do
  include FilterSpecHelper

  set(:project) { create(:project) }

  let(:url) { urls.metrics_dashboard_project_environment_url(project, 1, embedded: true) }
  let(:input) { %(<a href="#{url}">example</a>) }
  let(:doc) { filter(input) }

  context 'when the feature is disabled' do
    before do
      stub_feature_flags(gfm_embedded_metrics: false)
    end

    it 'does nothing' do
      expect(doc.to_s).to eq input
    end
  end

  context 'without a metrics charts placeholder' do
    it 'leaves regular non-metrics links unchanged' do
      expect(doc.to_s).to eq input
    end
  end

  context 'with a metrics charts placeholder' do
    let(:input) { %(<div class="js-render-metrics" data-dashboard-url="#{url}"></div>) }

    context 'no user is logged in' do
      it 'redacts the placeholder' do
        expect(doc.to_s).to be_empty
      end
    end

    context 'the user does not have permission do see charts' do
      let(:doc) { filter(input, current_user: build(:user)) }

      it 'redacts the placeholder' do
        expect(doc.to_s).to be_empty
      end
    end

    context 'the user has requisite permissions' do
      let(:user) { create(:user) }
      let(:doc) { filter(input, current_user: user) }

      it 'leaves the placeholder' do
        project.add_maintainer(user)

        expect(doc.to_s).to eq input
      end
    end
  end
end
