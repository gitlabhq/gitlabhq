# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifact, type: :model do
  let(:coverage_report) { create(:ci_pipeline_artifact, :with_coverage_report) }

  describe 'associations' do
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to belong_to(:project) }
  end

  it_behaves_like 'having unique enum values'

  it_behaves_like 'UpdateProjectStatistics' do
    let_it_be(:pipeline, reload: true) { create(:ci_pipeline) }

    subject { build(:ci_pipeline_artifact, :with_code_coverage_with_multiple_files, pipeline: pipeline) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:pipeline) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:file_type) }
    it { is_expected.to validate_presence_of(:file_format) }
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_presence_of(:file) }

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

  describe 'scopes' do
    describe '.unlocked' do
      subject(:pipeline_artifacts) { described_class.unlocked }

      context 'when pipeline is locked' do
        it 'returns an empty collection' do
          expect(pipeline_artifacts).to be_empty
        end
      end

      context 'when pipeline is unlocked' do
        before do
          create(:ci_pipeline_artifact, :with_coverage_report)
        end

        it 'returns unlocked artifacts' do
          codequality_report = create(:ci_pipeline_artifact, :with_codequality_mr_diff_report, :unlocked)

          expect(pipeline_artifacts).to eq([codequality_report])
        end
      end
    end
  end

  describe 'file is being stored' do
    subject { create(:ci_pipeline_artifact, :with_coverage_report) }

    context 'when existing object has local store' do
      it_behaves_like 'mounted file in local store'
    end

    context 'when direct upload is enabled' do
      before do
        stub_artifacts_object_storage(Ci::PipelineArtifactUploader, direct_upload: true)
      end

      context 'when file is stored' do
        it_behaves_like 'mounted file in object store'
      end
    end

    context 'when file contains multi-byte characters' do
      let(:coverage_report_multibyte) { create(:ci_pipeline_artifact, :with_coverage_multibyte_characters) }

      it 'sets the size in bytesize' do
        expect(coverage_report_multibyte.size).to eq(14)
      end
    end
  end

  describe '.report_exists?' do
    subject(:pipeline_artifact) { Ci::PipelineArtifact.report_exists?(file_type) }

    context 'when file_type is code_coverage' do
      let(:file_type) { :code_coverage }

      context 'when pipeline artifact has a coverage report' do
        let!(:pipeline_artifact) { create(:ci_pipeline_artifact, :with_coverage_report) }

        it 'returns true' do
          expect(pipeline_artifact).to be_truthy
        end
      end

      context 'when pipeline artifact does not have a coverage report' do
        it 'returns false' do
          expect(pipeline_artifact).to be_falsey
        end
      end
    end

    context 'when file_type is code_quality_mr_diff' do
      let(:file_type) { :code_quality_mr_diff }

      context 'when pipeline artifact has a codequality mr diff report' do
        let!(:pipeline_artifact) { create(:ci_pipeline_artifact, :with_codequality_mr_diff_report) }

        it 'returns true' do
          expect(pipeline_artifact).to be_truthy
        end
      end

      context 'when pipeline artifact does not have a codequality mr diff report' do
        it 'returns false' do
          expect(pipeline_artifact).to be_falsey
        end
      end
    end

    context 'when file_type is nil' do
      let(:file_type) { nil }

      it 'returns false' do
        expect(pipeline_artifact).to be_falsey
      end
    end
  end

  describe '.find_by_file_type' do
    subject(:pipeline_artifact) { Ci::PipelineArtifact.find_by_file_type(file_type) }

    context 'when file_type is code_coverage' do
      let(:file_type) { :code_coverage }

      context 'when pipeline artifact has a coverage report' do
        let!(:coverage_report) { create(:ci_pipeline_artifact, :with_coverage_report) }

        it 'returns a pipeline artifact with a coverage report' do
          expect(pipeline_artifact.file_type).to eq('code_coverage')
        end
      end

      context 'when pipeline artifact does not have a coverage report' do
        it 'returns nil' do
          expect(pipeline_artifact).to be_nil
        end
      end
    end

    context 'when file_type is code_quality_mr_diff' do
      let(:file_type) { :code_quality_mr_diff }

      context 'when pipeline artifact has a quality report' do
        let!(:coverage_report) { create(:ci_pipeline_artifact, :with_codequality_mr_diff_report) }

        it 'returns a pipeline artifact with a quality report' do
          expect(pipeline_artifact.file_type).to eq('code_quality_mr_diff')
        end
      end

      context 'when pipeline artifact does not have a quality report' do
        it 'returns nil' do
          expect(pipeline_artifact).to be_nil
        end
      end
    end

    context 'when file_type is nil' do
      let(:file_type) { nil }

      it 'returns nil' do
        expect(pipeline_artifact).to be_nil
      end
    end
  end

  describe '#present' do
    subject(:presenter) { report.present }

    context 'when file_type is code_coverage' do
      let(:report) { coverage_report }

      it 'uses code coverage presenter' do
        expect(presenter).to be_kind_of(Ci::PipelineArtifacts::CodeCoveragePresenter)
      end
    end

    context 'when file_type is code_quality_mr_diff' do
      let(:report) { create(:ci_pipeline_artifact, :with_codequality_mr_diff_report) }

      it 'uses code codequality mr diff presenter' do
        expect(presenter).to be_kind_of(Ci::PipelineArtifacts::CodeQualityMrDiffPresenter)
      end
    end
  end
end
