require 'spec_helper'

describe BuildSuccessWorker do
  describe '#perform' do
    context 'when build exists' do
      context 'when build belogs to the environment' do
        let!(:build) { create(:ci_build, environment: 'production') }

        it 'executes deployment service' do
          expect_any_instance_of(CreateDeploymentService)
            .to receive(:execute)

          described_class.new.perform(build.id)
        end
      end

      context 'when build is not associated with project' do
        let!(:build) { create(:ci_build, project: nil) }

        it 'does not create deployment' do
          expect_any_instance_of(CreateDeploymentService)
            .not_to receive(:execute)

          described_class.new.perform(build.id)
        end
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end
end
