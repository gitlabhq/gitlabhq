# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::AnnotationPolicy, :models do
  let(:policy) { described_class.new(user, annotation) }

  let_it_be(:user) { create(:user) }

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
      let_it_be(:environment) { create(:environment) }
      let_it_be(:annotation) { create(:metrics_dashboard_annotation, environment: environment) }

      it_behaves_like 'metrics dashboard annotation policy' do
        let(:project) { environment.project }
      end
    end

    context 'cluster annotation' do
      let_it_be(:cluster) { create(:cluster, :project) }
      let_it_be(:annotation) { create(:metrics_dashboard_annotation, environment: nil, cluster: cluster) }

      it_behaves_like 'metrics dashboard annotation policy' do
        let(:project) { cluster.project }
      end
    end
  end
end
