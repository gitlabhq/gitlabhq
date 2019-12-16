# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::InlineMetricsRedactorFilter do
  include FilterSpecHelper

  set(:project) { create(:project) }

  let(:url) { urls.metrics_dashboard_project_environment_url(project, 1, embedded: true) }
  let(:input) { %(<a href="#{url}">example</a>) }
  let(:doc) { filter(input) }

  context 'without a metrics charts placeholder' do
    it 'leaves regular non-metrics links unchanged' do
      expect(doc.to_s).to eq input
    end
  end

  context 'with a metrics charts placeholder' do
    shared_examples_for 'a supported metrics dashboard url' do
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

    let(:input) { %(<div class="js-render-metrics" data-dashboard-url="#{url}"></div>) }

    it_behaves_like 'a supported metrics dashboard url'

    context 'for a grafana dashboard' do
      let(:url) { urls.project_grafana_api_metrics_dashboard_url(project, embedded: true) }

      it_behaves_like 'a supported metrics dashboard url'
    end

    context 'the user has requisite permissions' do
      let(:user) { create(:user) }
      let(:doc) { filter(input, current_user: user) }

      before do
        project.add_maintainer(user)
      end

      context 'for an internal non-dashboard url' do
        let(:url) { urls.project_url(project) }

        it 'leaves the placeholder' do
          expect(doc.to_s).to be_empty
        end
      end

      context 'with over 100 embeds' do
        let(:embed) { %(<div class="js-render-metrics" data-dashboard-url="#{url}"></div>) }
        let(:input) { embed * 150 }

        it 'redacts ill-advised embeds' do
          expect(doc.to_s.length).to eq(embed.length * 100)
        end
      end
    end
  end
end
