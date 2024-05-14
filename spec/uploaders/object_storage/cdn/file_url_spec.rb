# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::CDN::FileUrl, feature_category: :source_code_management do
  subject(:file_url) do
    described_class.new(
      file: file,
      ip_address: ip_address,
      redirect_params: redirect_params)
  end

  let(:ip_address) { '127.0.0.1' }
  let(:redirect_params) { {} }

  describe '#url' do
    before do
      stub_artifacts_object_storage(enabled: true)
    end

    context 'with a CI artifact' do
      let(:file) { create(:ci_job_artifact, :zip, :remote_store).file }

      it 'retrieves a CDN-frontend URL' do
        expect(::Gitlab::ApplicationContext).to receive(:push).with(artifact_used_cdn: false).and_call_original
        expect(file_url.url).to be_a(String)
      end
    end

    context 'with a file upload' do
      let(:expected_url) { 'https://example.com/path/to/upload' }
      let(:file) { instance_double(::GitlabUploader, url: expected_url) }

      it 'retrieves the file URL' do
        expect(::Gitlab::ApplicationContext).not_to receive(:push)
        expect(file_url.url).to eq(expected_url)
      end
    end
  end
end
