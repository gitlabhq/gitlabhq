# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifact, type: :model do
  let_it_be(:coverage_report) { create(:ci_pipeline_artifact) }

  describe 'associations' do
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to belong_to(:project) }
  end

  it_behaves_like 'having unique enum values'

  describe 'validations' do
    it { is_expected.to validate_presence_of(:pipeline) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:file_type) }
    it { is_expected.to validate_presence_of(:file_format) }
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_uniqueness_of(:file_type).scoped_to([:pipeline_id]).ignoring_case_sensitivity }

    context 'when attributes are valid' do
      it 'returns no errors' do
        expect(coverage_report).to be_valid
      end
    end

    context 'when file_store is invalid' do
      it 'returns errors' do
        coverage_report.file_store = 0

        expect(coverage_report).to be_invalid
        expect(coverage_report.errors.full_messages).to eq(["File store is not included in the list"])
      end
    end

    context 'when size is over 10 megabytes' do
      it 'returns errors' do
        coverage_report.size = 11.megabytes

        expect(coverage_report).to be_invalid
      end
    end
  end
end
