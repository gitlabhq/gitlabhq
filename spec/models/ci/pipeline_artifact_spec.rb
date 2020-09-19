# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifact, type: :model do
  let(:coverage_report) { create(:ci_pipeline_artifact) }

  describe 'associations' do
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to belong_to(:project) }
  end

  it_behaves_like 'having unique enum values'

  it_behaves_like 'UpdateProjectStatistics' do
    let_it_be(:pipeline, reload: true) { create(:ci_pipeline) }

    subject { build(:ci_pipeline_artifact, pipeline: pipeline) }
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

  describe 'file is being stored' do
    subject { create(:ci_pipeline_artifact) }

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
      let(:coverage_report_multibyte) { create(:ci_pipeline_artifact, :with_multibyte_characters) }

      it 'sets the size in bytesize' do
        expect(coverage_report_multibyte.size).to eq(14)
      end
    end
  end

  describe '.has_code_coverage?' do
    subject { Ci::PipelineArtifact.has_code_coverage? }

    context 'when pipeline artifact has a code coverage' do
      let!(:pipeline_artifact) { create(:ci_pipeline_artifact) }

      it 'returns true' do
        expect(subject).to be_truthy
      end
    end

    context 'when pipeline artifact does not have a code coverage' do
      it 'returns false' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '.find_with_code_coverage' do
    subject { Ci::PipelineArtifact.find_with_code_coverage }

    context 'when pipeline artifact has a coverage report' do
      let!(:coverage_report) { create(:ci_pipeline_artifact) }

      it 'returns a pipeline artifact with a code coverage' do
        expect(subject.file_type).to eq('code_coverage')
      end
    end

    context 'when pipeline artifact does not have a coverage report' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#present' do
    subject { coverage_report.present }

    context 'when file_type is code_coverage' do
      it 'uses code coverage presenter' do
        expect(subject.present).to be_kind_of(Ci::PipelineArtifacts::CodeCoveragePresenter)
      end
    end
  end
end
