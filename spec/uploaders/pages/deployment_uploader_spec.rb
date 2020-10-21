# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeploymentUploader do
  let(:pages_deployment) { create(:pages_deployment) }
  let(:uploader) { described_class.new(pages_deployment, :file) }

  let(:file) do
    fixture_file_upload("spec/fixtures/pages.zip")
  end

  subject { uploader }

  it_behaves_like "builds correct paths",
                  store_dir: %r[/\h{2}/\h{2}/\h{64}/pages_deployments/\d+],
                  cache_dir: %r[pages/@hashed/tmp/cache],
                  work_dir: %r[pages/@hashed/tmp/work]

  context 'when object store is REMOTE' do
    before do
      stub_pages_object_storage
    end

    it_behaves_like 'builds correct paths', store_dir: %r[\A\h{2}/\h{2}/\h{64}/pages_deployments/\d+\z]

    it 'preserves original file when stores it' do
      uploader.store!(file)

      expect(File.exist?(file.path)).to be true
    end
  end

  context 'when file is stored in valid local_path' do
    before do
      uploader.store!(file)
    end

    subject { uploader.file.path }

    it { is_expected.to match(%r[#{uploader.root}/@hashed/\h{2}/\h{2}/\h{64}/pages_deployments/#{pages_deployment.id}/pages.zip]) }

    it 'preserves original file when stores it' do
      expect(File.exist?(file.path)).to be true
    end
  end

  describe '.default_store' do
    it 'returns local store when object storage is not enabled' do
      expect(described_class.default_store).to eq(ObjectStorage::Store::LOCAL)
    end

    it 'returns remote store when object storage is enabled' do
      stub_pages_object_storage

      expect(described_class.default_store).to eq(ObjectStorage::Store::REMOTE)
    end
  end
end
