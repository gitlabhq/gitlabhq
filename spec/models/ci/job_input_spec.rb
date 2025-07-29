# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobInput, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:job) { create(:ci_build, project: project) }
  let_it_be_with_reload(:job_input) { create(:ci_job_input, job: job, project: project) }

  subject(:input) { job_input }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_job_input, project: project) }
    let!(:parent) { model.project }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:job) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    describe 'name' do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_length_of(:name).is_at_most(255) }
      it { is_expected.to validate_uniqueness_of(:name).scoped_to([:job_id, :partition_id]) }
    end

    describe 'project' do
      it { is_expected.to validate_presence_of(:project) }
    end

    describe 'value' do
      context 'when the serialized length of the value is less than the maximum permitted size' do
        it 'is valid' do
          input.value = [1, 2]

          expect(input).to be_valid
        end
      end

      context 'when the serialized length of the value is greater than the maximum permitted size' do
        it 'is invalid' do
          stub_const("#{described_class}::MAX_VALUE_SIZE", 4)

          input.value = [1, 2]

          expect(input).not_to be_valid
          expect(input.errors.full_messages).to contain_exactly('Value exceeds max serialized size: 4 characters')
        end
      end
    end
  end
end
