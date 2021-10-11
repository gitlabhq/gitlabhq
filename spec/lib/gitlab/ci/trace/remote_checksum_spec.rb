# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Trace::RemoteChecksum do
  let_it_be(:job) { create(:ci_build, :success) }

  let(:file_store) { JobArtifactUploader::Store::LOCAL }
  let(:trace_artifact) { create(:ci_job_artifact, :trace, job: job, file_store: file_store) }
  let(:checksum) { Digest::MD5.hexdigest(trace_artifact.file.read) }
  let(:base64checksum) { Digest::MD5.base64digest(trace_artifact.file.read) }
  let(:fetcher) { described_class.new(trace_artifact) }

  describe '#md5_checksum' do
    subject { fetcher.md5_checksum }

    context 'when the file is stored locally' do
      it { is_expected.to be_nil }
    end

    context 'when object store is enabled' do
      before do
        stub_artifacts_object_storage
      end

      context 'with local files' do
        it { is_expected.to be_nil }
      end

      context 'with remote files' do
        let(:file_store) { JobArtifactUploader::Store::REMOTE }

        context 'when the feature flag is disabled' do
          before do
            stub_feature_flags(ci_archived_build_trace_checksum: false)
          end

          it { is_expected.to be_nil }
        end

        context 'with AWS as provider' do
          it { is_expected.to eq(checksum) }
        end

        context 'with Google as provider' do
          let(:metadata) {{ content_md5: base64checksum }}

          before do
            expect(fetcher).to receive(:provider_google?) { true }
            expect(fetcher).not_to receive(:provider_aws?) { false }

            allow(trace_artifact.file.file)
              .to receive(:attributes)
              .and_return(metadata)
          end

          it { is_expected.to eq(checksum) }
        end

        context 'with unsupported providers' do
          let(:file_store) { JobArtifactUploader::Store::REMOTE }

          before do
            expect(fetcher).to receive(:provider_aws?) { false }
            expect(fetcher).to receive(:provider_google?) { false }
          end

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
