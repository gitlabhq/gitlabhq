# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildSource, feature_category: :continuous_integration do
  it { is_expected.to belong_to(:job) }

  describe 'validation' do
    it { is_expected.to validate_presence_of(:job) }
  end

  describe 'partitioning' do
    context 'with job' do
      let_it_be(:job) { FactoryBot.build(:ci_build, partition_id: ci_testing_partition_id) }
      let_it_be(:job_name) { FactoryBot.build(:ci_build_source, job: job) }

      it 'sets partition_id to the current partition value' do
        expect { job_name.valid? }.to change { job_name.partition_id }.to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let_it_be(:job_name) { FactoryBot.build(:ci_build_source, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { job_name.valid? }.not_to change { job_name.partition_id }
        end
      end
    end
  end
end
