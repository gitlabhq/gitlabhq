# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::AutoDeleteCronWorker, feature_category: :continuous_delivery do
  include CreateEnvironmentsHelpers

  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }

    let_it_be(:project) { create(:project, :repository) }

    let!(:environment) { create(:environment, :auto_deletable, project: project) }

    it 'deletes the environment' do
      expect { subject }.to change { Environment.count }.by(-1)
    end

    context 'when environment is not stopped' do
      let!(:environment) { create(:environment, :available, auto_delete_at: 1.day.ago, project: project) }

      it 'does not delete the environment' do
        expect { subject }.not_to change { Environment.count }
      end
    end

    context 'when auto_delete_at is null' do
      let!(:environment) { create(:environment, :stopped, auto_delete_at: nil, project: project) }

      it 'does not delete the environment' do
        expect { subject }.not_to change { Environment.count }
      end
    end

    context 'with multiple deletable environments' do
      let!(:other_environment) { create(:environment, :auto_deletable, project: project) }

      it 'deletes all deletable environments' do
        expect { subject }.to change { Environment.count }.by(-2)
      end

      context 'when loop reached loop limit' do
        before do
          stub_const("#{described_class}::LOOP_LIMIT", 1)
          stub_const("#{described_class}::BATCH_SIZE", 1)
        end

        it 'deletes only one deletable environment' do
          expect { subject }.to change { Environment.count }.by(-1)
        end
      end

      context 'when batch size is less than the number of environments' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 1)
        end

        it 'deletes all deletable environments' do
          expect { subject }.to change { Environment.count }.by(-2)
        end
      end
    end

    context 'with multiple deployments' do
      it 'deletes the deployment records and refs' do
        deployment_1 = create(:deployment, environment: environment, project: project)
        deployment_2 = create(:deployment, environment: environment, project: project)
        deployment_1.create_ref
        deployment_2.create_ref

        expect(project.repository.commit(deployment_1.ref_path)).to be_present
        expect(project.repository.commit(deployment_2.ref_path)).to be_present

        expect { subject }.to change { Deployment.count }.by(-2)

        expect(project.repository.commit(deployment_1.ref_path)).not_to be_present
        expect(project.repository.commit(deployment_2.ref_path)).not_to be_present
      end
    end

    context 'when loop reached timeout' do
      before do
        stub_const("#{described_class}::LOOP_TIMEOUT", 0.seconds)
        stub_const("#{described_class}::LOOP_LIMIT", 100_000)
        allow_next_instance_of(described_class) do |worker|
          allow(worker).to receive(:destroy_in_batch) { true }
        end
      end

      it 'does not delete the environment' do
        expect { subject }.not_to change { Environment.count }
      end
    end

    context 'with idempotent flag' do
      include_examples 'an idempotent worker' do
        it 'deletes the environment' do
          expect { subject }.to change { Environment.count }.by(-1)
        end
      end
    end
  end
end
