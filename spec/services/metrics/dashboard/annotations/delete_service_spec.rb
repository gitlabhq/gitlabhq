# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::Annotations::DeleteService do
  let(:user) { create(:user) }
  let(:service_instance) { described_class.new(user, annotation) }

  shared_examples 'executed annotation deletion' do
    it 'returns success response', :aggregate_failures do
      expect(annotation).to receive(:destroy).and_return(true)

      response = service_instance.execute

      expect(response[:status]).to be :success
    end
  end

  shared_examples 'prevented annotation deletion' do |message|
    it 'returns error response', :aggregate_failures do
      response = service_instance.execute

      expect(response[:status]).to be :error
      expect(response[:message]).to eql message
    end

    it 'does not change db state' do
      expect(annotation).not_to receive(:destroy)

      service_instance.execute
    end
  end

  describe '.execute' do
    context 'with specific environment' do
      let(:annotation) { create(:metrics_dashboard_annotation, environment: environment) }
      let(:environment) { create(:environment) }

      context 'with anonymous user' do
        it_behaves_like 'prevented annotation deletion', 'You are not authorized to delete this annotation'
      end

      context 'with maintainer user' do
        before do
          environment.project.add_maintainer(user)
        end

        it_behaves_like 'executed annotation deletion'

        context 'annotation failed to delete' do
          it 'returns error response', :aggregate_failures do
            allow(annotation).to receive(:destroy).and_return(false)

            response = service_instance.execute

            expect(response[:status]).to be :error
            expect(response[:message]).to eql 'Annotation has not been deleted'
          end
        end
      end
    end

    context 'with specific cluster' do
      let(:annotation) { create(:metrics_dashboard_annotation, cluster: cluster, environment: nil) }

      context 'with anonymous user' do
        let(:cluster) { create(:cluster, :project) }

        it_behaves_like 'prevented annotation deletion', 'You are not authorized to delete this annotation'
      end

      context 'with maintainer user' do
        let(:cluster) { create(:cluster, :project) }

        before do
          cluster.project.add_maintainer(user)
        end

        it_behaves_like 'executed annotation deletion'
      end

      context 'with owner user' do
        let(:cluster) { create(:cluster, :group) }

        before do
          cluster.group.add_owner(user)
        end

        it_behaves_like 'executed annotation deletion'
      end
    end
  end
end
