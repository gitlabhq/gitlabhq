# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::Annotations::CreateService do
  let_it_be(:user) { create(:user) }

  let(:description) { 'test annotation' }
  let(:dashboard_path) { 'config/prometheus/common_metrics.yml' }
  let(:starting_at) { 15.minutes.ago }
  let(:ending_at) { nil }
  let(:service_instance) { described_class.new(user, annotation_params) }
  let(:annotation_params) do
    {
      environment: environment,
      cluster: cluster,
      description: description,
      dashboard_path: dashboard_path,
      starting_at: starting_at,
      ending_at: ending_at
    }
  end

  shared_examples 'executed annotation creation' do
    it 'returns success response', :aggregate_failures do
      annotation = instance_double(::Metrics::Dashboard::Annotation)
      allow(::Metrics::Dashboard::Annotation).to receive(:new).and_return(annotation)
      allow(annotation).to receive(:save).and_return(true)

      response = service_instance.execute

      expect(response[:status]).to be :success
      expect(response[:annotation]).to be annotation
    end

    it 'creates annotation', :aggregate_failures do
      annotation = instance_double(::Metrics::Dashboard::Annotation)

      expect(::Metrics::Dashboard::Annotation)
        .to receive(:new).with(annotation_params).and_return(annotation)
      expect(annotation).to receive(:save).and_return(true)

      service_instance.execute
    end
  end

  shared_examples 'prevented annotation creation' do |message|
    it 'returns error response', :aggregate_failures do
      response = service_instance.execute

      expect(response[:status]).to be :error
      expect(response[:message]).to eql message
    end

    it 'does not change db state' do
      expect(::Metrics::Dashboard::Annotation).not_to receive(:new)

      service_instance.execute
    end
  end

  shared_examples 'annotation creation failure' do
    it 'returns error response', :aggregate_failures do
      annotation = instance_double(::Metrics::Dashboard::Annotation)

      expect(annotation).to receive(:errors).and_return('Model validation error')
      expect(::Metrics::Dashboard::Annotation)
        .to receive(:new).with(annotation_params).and_return(annotation)
      expect(annotation).to receive(:save).and_return(false)

      response = service_instance.execute

      expect(response[:status]).to be :error
      expect(response[:message]).to eql 'Model validation error'
    end
  end

  describe '.execute' do
    context 'with environment' do
      let(:environment) { create(:environment) }
      let(:cluster) { nil }

      context 'with anonymous user' do
        it_behaves_like 'prevented annotation creation', 'You are not authorized to create annotation for selected environment'
      end

      context 'with maintainer user' do
        before do
          environment.project.add_maintainer(user)
        end

        it_behaves_like 'executed annotation creation'
      end
    end

    context 'with cluster' do
      let(:environment) { nil }

      context 'with anonymous user' do
        let(:cluster) { create(:cluster, :project) }

        it_behaves_like 'prevented annotation creation', 'You are not authorized to create annotation for selected cluster'
      end

      context 'with maintainer user' do
        let(:cluster) { create(:cluster, :project) }

        before do
          cluster.project.add_maintainer(user)
        end

        it_behaves_like 'executed annotation creation'
      end

      context 'with owner user' do
        let(:cluster) { create(:cluster, :group) }

        before do
          cluster.group.add_owner(user)
        end

        it_behaves_like 'executed annotation creation'
      end
    end

    context 'non cluster nor environment is supplied' do
      let(:environment) { nil }
      let(:cluster) { nil }

      it_behaves_like 'annotation creation failure'
    end

    context 'missing dashboard_path' do
      let(:cluster) { create(:cluster, :project) }
      let(:environment) { nil }
      let(:dashboard_path) { nil }

      context 'with maintainer user' do
        before do
          cluster.project.add_maintainer(user)
        end

        it_behaves_like 'annotation creation failure'
      end
    end

    context 'incorrect dashboard_path' do
      let(:cluster) { create(:cluster, :project) }
      let(:environment) { nil }
      let(:dashboard_path) { 'something_incorrect.yml' }

      context 'with maintainer user' do
        before do
          cluster.project.add_maintainer(user)
        end

        it_behaves_like 'prevented annotation creation', 'Dashboard with requested path can not be found'
      end
    end
  end
end
