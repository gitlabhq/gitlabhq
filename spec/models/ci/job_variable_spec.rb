# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobVariable, feature_category: :continuous_integration do
  it_behaves_like "CI variable"

  describe 'associations' do
    let!(:job_variable) { create(:ci_job_variable) }

    it { is_expected.to belong_to(:job).class_name('Ci::Build').with_foreign_key(:job_id).inverse_of(:job_variables) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:job_id) }
  end

  describe 'partitioning' do
    let(:job_variable) { build(:ci_job_variable, job: ci_build) }

    context 'with build' do
      let(:ci_build) { build(:ci_build, partition_id: ci_testing_partition_id) }

      it 'copies the partition_id from build' do
        expect { job_variable.valid? }.to change { job_variable.partition_id }.to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let(:job_variable) { build(:ci_job_variable, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { job_variable.valid? }.not_to change { job_variable.partition_id }
        end
      end
    end

    context 'without build' do
      subject(:job_variable) { build(:ci_job_variable, job: nil, partition_id: 125) }

      it { is_expected.to validate_presence_of(:partition_id) }

      it 'does not change the partition_id value' do
        expect { job_variable.valid? }.not_to change { job_variable.partition_id }
      end
    end

    context 'when using bulk_insert', :ci_partitionable do
      include Ci::PartitioningHelpers

      let(:new_pipeline) { create(:ci_pipeline) }
      let(:ci_build) { create(:ci_build, pipeline: new_pipeline) }
      let(:job_variable_2) { build(:ci_job_variable, job: ci_build) }

      before do
        stub_current_partition_id(ci_testing_partition_id_for_check_constraints)
      end

      it 'creates job variables successfully', :aggregate_failures do
        described_class.bulk_insert!([job_variable, job_variable_2])

        expect(described_class.count).to eq(2)
        expect(described_class.first.partition_id).to eq(ci_testing_partition_id_for_check_constraints)
        expect(described_class.last.partition_id).to eq(ci_testing_partition_id_for_check_constraints)
      end
    end
  end
end
