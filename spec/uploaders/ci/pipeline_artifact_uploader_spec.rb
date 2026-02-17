# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifactUploader, feature_category: :continuous_integration do
  let(:pipeline_artifact) { create(:ci_pipeline_artifact) }
  let(:uploader) { described_class.new(pipeline_artifact, :file) }

  subject { uploader }

  it_behaves_like "builds correct paths",
    store_dir: %r[\h{2}/\h{2}/\h{64}/pipelines/\d+/artifacts/\d+],
    cache_dir: %r{artifacts/tmp/cache},
    work_dir: %r{artifacts/tmp/work}

  context 'when object store is REMOTE' do
    before do
      stub_artifacts_object_storage(described_class)
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths', store_dir: %r[\h{2}/\h{2}/\h{64}/pipelines/\d+/artifacts/\d+]
  end

  context 'when file is stored in valid local_path' do
    let(:file) do
      fixture_file_upload('spec/fixtures/pipeline_artifacts/code_coverage.json', 'application/json')
    end

    before do
      uploader.store!(file)
    end

    subject { uploader.file.path }

    it { is_expected.to match(%r[#{uploader.root}/#{uploader.class.base_dir}\h{2}/\h{2}/\h{64}/pipelines/#{pipeline_artifact.pipeline_id}/artifacts/#{pipeline_artifact.id}/code_coverage.json]) }
  end

  describe 'encryption' do
    context 'when file_type is pipeline_variables' do
      let(:pipeline_artifact) { create(:ci_pipeline_artifact, :with_pipeline_variables) }
      let(:expected_content) { [{ key: 'TEST_VAR', value: 'test_value', variable_type: 'env_var', raw: false }].to_json }

      it 'encrypts the file content' do
        raw_stored_data = pipeline_artifact.file.file.read
        expect(raw_stored_data).not_to eq(expected_content)
      end

      it 'decrypts the file content when reading' do
        expect(pipeline_artifact.file.read).to eq(expected_content)
      end
    end

    context 'when file_type is code_coverage' do
      let(:pipeline_artifact) { create(:ci_pipeline_artifact, :with_coverage_report) }

      it 'does not encrypt the file content' do
        original_content = File.read(Rails.root.join('spec/fixtures/pipeline_artifacts/code_coverage.json'))
        expect(pipeline_artifact.file.file.read).to eq(original_content)
        expect(pipeline_artifact.file.read).to eq(original_content)
      end
    end

    context 'when file_type is code_quality_mr_diff' do
      let(:pipeline_artifact) { create(:ci_pipeline_artifact, :with_codequality_mr_diff_report) }

      it 'does not encrypt the file content' do
        original_content = File.read(Rails.root.join('spec/fixtures/pipeline_artifacts/code_quality_mr_diff.json'))
        expect(pipeline_artifact.file.file.read).to eq(original_content)
        expect(pipeline_artifact.file.read).to eq(original_content)
      end
    end

    context 'when stored data is nil' do
      let(:pipeline_artifact) { create(:ci_pipeline_artifact, :with_pipeline_variables) }

      it 'returns nil without attempting to decrypt' do
        uploader = described_class.new(pipeline_artifact, :file)

        expect(uploader.read).to be_nil
      end
    end
  end

  describe '#encryption_key' do
    let(:pipeline_artifact) { create(:ci_pipeline_artifact) }
    let(:uploader) { described_class.new(pipeline_artifact, :file) }

    it 'generates a deterministic key based on project_id' do
      key1 = uploader.send(:encryption_key)
      key2 = uploader.send(:encryption_key)

      expect(key1).to eq(key2)
    end

    it 'generates different keys for different projects' do
      other_artifact = create(:ci_pipeline_artifact)
      other_uploader = described_class.new(other_artifact, :file)

      key1 = uploader.send(:encryption_key)
      key2 = other_uploader.send(:encryption_key)

      expect(key1).not_to eq(key2)
    end
  end
end
