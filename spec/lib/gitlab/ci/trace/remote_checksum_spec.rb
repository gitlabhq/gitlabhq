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

        context 'with AWS as provider' do
          it { is_expected.to eq(checksum) }
        end

        context 'with Google as provider' do
          before do
            spy_file = spy(:file)
            expect(fetcher).to receive(:provider_google?) { true }
            expect(fetcher).not_to receive(:provider_aws?) { false }
            allow(spy_file).to receive(:attributes).and_return(metadata)

            allow_next_found_instance_of(Ci::JobArtifact) do |trace_artifact|
              allow(trace_artifact.file).to receive(:file) { spy_file }
            end
          end

          context 'when the response does not include :content_md5' do
            let(:metadata) { {} }

            it 'raises an exception' do
              expect { subject }.to raise_error KeyError, /content_md5/
            end
          end

          context 'when the response include :content_md5' do
            let(:metadata) { { content_md5: base64checksum } }

            it { is_expected.to eq(checksum) }
          end
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
