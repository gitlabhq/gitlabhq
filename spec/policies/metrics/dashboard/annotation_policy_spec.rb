# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::AnnotationPolicy, :models do
  shared_examples 'metrics dashboard annotation policy' do
    context 'when guest' do
      before do
        project.add_guest(user)
      end

      it { expect(policy).to be_disallowed :read_metrics_dashboard_annotation }
      it { expect(policy).to be_disallowed :create_metrics_dashboard_annotation }
      it { expect(policy).to be_disallowed :update_metrics_dashboard_annotation }
      it { expect(policy).to be_disallowed :delete_metrics_dashboard_annotation }
    end

    context 'when reporter' do
      before do
        project.add_reporter(user)
      end

      it { expect(policy).to be_allowed :read_metrics_dashboard_annotation }
      it { expect(policy).to be_disallowed :create_metrics_dashboard_annotation }
      it { expect(policy).to be_disallowed :update_metrics_dashboard_annotation }
      it { expect(policy).to be_disallowed :delete_metrics_dashboard_annotation }
    end

    context 'when developer' do
      before do
        project.add_developer(user)
      end

      it { expect(policy).to be_allowed :read_metrics_dashboard_annotation }
      it { expect(policy).to be_allowed :create_metrics_dashboard_annotation }
      it { expect(policy).to be_allowed :update_metrics_dashboard_annotation }
      it { expect(policy).to be_allowed :delete_metrics_dashboard_annotation }
    end

    context 'when maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { expect(policy).to be_allowed :read_metrics_dashboard_annotation }
      it { expect(policy).to be_allowed :create_metrics_dashboard_annotation }
      it { expect(policy).to be_allowed :update_metrics_dashboard_annotation }
      it { expect(policy).to be_allowed :delete_metrics_dashboard_annotation }
    end
  end

  describe 'rules' do
    context 'environments annotation' do
      let(:annotation) { create(:metrics_dashboard_annotation, environment: environment) }
      let(:environment) { create(:environment) }
      let!(:project) { environment.project }
      let(:user) { create(:user) }
      let(:policy) { described_class.new(user, annotation) }

      it_behaves_like 'metrics dashboard annotation policy'
    end

    context 'cluster annotation' do
      let(:annotation) { create(:metrics_dashboard_annotation, environment: nil, cluster: cluster) }
      let(:cluster) { create(:cluster, :project) }
      let(:project) { cluster.project }
      let(:user) { create(:user) }
      let(:policy) { described_class.new(user, annotation) }

      it_behaves_like 'metrics dashboard annotation policy'
    end
  end
end
