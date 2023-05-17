# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::ArchiveInProjectService, feature_category: :continuous_delivery do
  let_it_be(:project) { create(:project, :repository) }

  let(:service) { described_class.new(project, nil) }

  describe '#execute' do
    subject { service.execute }

    context 'when there are archivable deployments' do
      let!(:deployments) { create_list(:deployment, 3, project: project) }
      let!(:deployment_refs) { deployments.map(&:ref_path) }

      before do
        deployments.each(&:create_ref)
        allow(Deployment).to receive(:archivables_in) { deployments }
      end

      it 'returns result code' do
        expect(subject[:result]).to eq(:archived)
        expect(subject[:status]).to eq(:success)
        expect(subject[:count]).to eq(3)
      end

      it 'archives the deployment' do
        expect(deployments.map(&:archived?)).to be_all(false)
        expect(deployment_refs_exist?).to be_all(true)

        subject

        deployments.each(&:reload)
        expect(deployments.map(&:archived?)).to be_all(true)
        expect(deployment_refs_exist?).to be_all(false)
      end

      context 'when ref does not exist by some reason' do
        before do
          project.repository.delete_refs(*deployment_refs)
        end

        it 'does not raise an error' do
          expect(deployment_refs_exist?).to be_all(false)

          expect { subject }.not_to raise_error

          expect(deployment_refs_exist?).to be_all(false)
        end
      end

      def deployment_refs_exist?
        deployment_refs.map { |path| project.repository.ref_exists?(path) }
      end
    end

    context 'when there are no archivable deployments' do
      before do
        allow(Deployment).to receive(:archivables_in) { Deployment.none }
      end

      it 'returns result code' do
        expect(subject[:result]).to eq(:empty)
        expect(subject[:status]).to eq(:success)
      end
    end
  end
end
