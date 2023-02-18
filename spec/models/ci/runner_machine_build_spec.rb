# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerMachineBuild, model: true, feature_category: :runner_fleet do
  it { is_expected.to belong_to(:build) }
  it { is_expected.to belong_to(:runner_machine) }

  describe 'partitioning' do
    context 'with build' do
      let(:build) { FactoryBot.build(:ci_build, partition_id: ci_testing_partition_id) }
      let(:runner_machine_build) { FactoryBot.build(:ci_runner_machine_build, build: build) }

      it 'sets partition_id to the current partition value' do
        expect { runner_machine_build.valid? }.to change { runner_machine_build.partition_id }
          .to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let(:runner_machine_build) { FactoryBot.build(:ci_runner_machine_build, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { runner_machine_build.valid? }.not_to change { runner_machine_build.partition_id }
        end
      end
    end

    context 'without build' do
      let(:runner_machine_build) { FactoryBot.build(:ci_runner_machine_build, build: nil) }

      it { is_expected.to validate_presence_of(:partition_id) }

      it 'does not change the partition_id value' do
        expect { runner_machine_build.valid? }.not_to change { runner_machine_build.partition_id }
      end
    end
  end
end
