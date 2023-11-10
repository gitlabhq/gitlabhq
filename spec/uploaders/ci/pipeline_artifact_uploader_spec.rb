# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifactUploader do
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
end
