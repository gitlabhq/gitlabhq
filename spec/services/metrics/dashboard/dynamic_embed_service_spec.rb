# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::DynamicEmbedService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  let_it_be(:project) { build(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
  end

  let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
  let(:group) { 'Group A' }
  let(:title) { 'Super Chart A1' }
  let(:y_label) { 'y_label' }

  describe '.valid_params?' do
    let(:valid_params) do
      {
        embedded: true,
        dashboard_path: dashboard_path,
        group: group,
        title: title,
        y_label: y_label
      }
    end

    subject { described_class.valid_params?(params) }

    let(:params) { valid_params }

    it { is_expected.to be_truthy }

    context 'not embedded' do
      let(:params) { valid_params.except(:embedded) }

      it { is_expected.to be_falsey }
    end

    context 'undefined dashboard' do
      let(:params) { valid_params.except(:dashboard_path) }

      it { is_expected.to be_truthy }
    end

    context 'missing dashboard' do
      let(:dashboard) { '' }

      it { is_expected.to be_truthy }
    end

    context 'missing group' do
      let(:group) { '' }

      it { is_expected.to be_falsey }
    end

    context 'missing title' do
      let(:title) { '' }

      it { is_expected.to be_falsey }
    end

    context 'undefined y-axis label' do
      let(:params) { valid_params.except(:y_label) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#get_dashboard' do
    let(:service_params) do
      [
        project,
        user,
        {
          environment: environment,
          dashboard_path: dashboard_path,
          group: group,
          title: title,
          y_label: y_label
        }
      ]
    end

    let(:service_call) { described_class.new(*service_params).get_dashboard }

    context 'when the dashboard does not exist' do
      it_behaves_like 'misconfigured dashboard service response', :not_found
    end

    context 'when the dashboard is exists' do
      let(:project) { project_with_dashboard(dashboard_path) }

      it_behaves_like 'valid embedded dashboard service response'
      it_behaves_like 'raises error for users with insufficient permissions'

      it 'caches the unprocessed dashboard for subsequent calls' do
        expect(YAML).to receive(:safe_load).once.and_call_original

        described_class.new(*service_params).get_dashboard
        described_class.new(*service_params).get_dashboard
      end

      context 'when the specified group is not present on the dashboard' do
        let(:group) { 'Group Not Found' }

        it_behaves_like 'misconfigured dashboard service response', :not_found
      end

      context 'when the specified title is not present on the dashboard' do
        let(:title) { 'Title Not Found' }

        it_behaves_like 'misconfigured dashboard service response', :not_found
      end

      context 'when the specified y-axis label is not present on the dashboard' do
        let(:y_label) { 'Y-Axis Not Found' }

        it_behaves_like 'misconfigured dashboard service response', :not_found
      end
    end

    shared_examples 'uses system dashboard' do
      it 'uses the default dashboard' do
        expect(Gitlab::Metrics::Dashboard::Finder)
        .to receive(:find_raw)
        .with(project, dashboard_path: system_dashboard_path)
        .once

        service_call
      end
    end

    context 'when the dashboard is nil' do
      let(:dashboard_path) { nil }

      it_behaves_like 'uses system dashboard'
    end

    context 'when the dashboard is not present' do
      let(:dashboard_path) { '' }

      it_behaves_like 'uses system dashboard'
    end
  end
end
