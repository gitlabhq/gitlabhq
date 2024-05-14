# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Trace::Archive, feature_category: :scalability do
  context 'with transactional fixtures' do
    let_it_be_with_reload(:job) { create(:ci_build, :success, :trace_live) }
    let_it_be_with_reload(:trace_metadata) { create(:ci_build_trace_metadata, build: job) }
    let_it_be(:src_checksum) do
      job.trace.read { |stream| Digest::MD5.hexdigest(stream.raw) }
    end

    let(:metrics) { spy('metrics') }

    describe '#execute' do
      subject { described_class.new(job, trace_metadata, metrics) }

      it 'computes and assigns checksum' do
        Gitlab::Ci::Trace::ChunkedIO.new(job) do |stream|
          expect { subject.execute!(stream) }.to change { Ci::JobArtifact.count }.by(1)
        end

        expect(trace_metadata.checksum).to eq(src_checksum)
        expect(trace_metadata.trace_artifact).to eq(job.job_artifacts_trace)
      end

      context 'validating artifact checksum' do
        let(:trace) { 'abc' }
        let(:stream) { StringIO.new(trace, 'rb') }
        let(:src_checksum) { Digest::MD5.hexdigest(trace) }

        shared_examples 'valid' do
          it 'does not count as invalid' do
            subject.execute!(stream)

            expect(metrics)
            .not_to have_received(:increment_error_counter)
            .with(error_reason: :archive_invalid_checksum)
          end
        end

        shared_examples 'local checksum only' do
          it 'generates only local checksum' do
            subject.execute!(stream)

            expect(trace_metadata.checksum).to eq(src_checksum)
            expect(trace_metadata.remote_checksum).to be_nil
          end
        end

        shared_examples 'skips validations' do
          it_behaves_like 'valid'
          it_behaves_like 'local checksum only'
        end

        shared_context 'with FIPS' do
          context 'with FIPS enabled', :fips_mode do
            it_behaves_like 'valid'

            it 'does not generate md5 checksums' do
              subject.execute!(stream)

              expect(trace_metadata.checksum).to be_nil
              expect(trace_metadata.remote_checksum).to be_nil
            end
          end
        end

        context 'when the object store is disabled' do
          before do
            stub_artifacts_object_storage(enabled: false)
          end

          it_behaves_like 'skips validations'
          include_context 'with FIPS'
        end

        context 'with direct_upload enabled' do
          before do
            stub_artifacts_object_storage(direct_upload: true)
          end

          it_behaves_like 'valid'

          it 'checksums match' do
            subject.execute!(stream)

            expect(trace_metadata.checksum).to eq(src_checksum)
            expect(trace_metadata.remote_checksum).to eq(src_checksum)
          end

          context 'when the checksum does not match' do
            let(:invalid_remote_checksum) { SecureRandom.hex }

            before do
              allow(::Gitlab::Ci::Trace::RemoteChecksum)
                .to receive(:new)
                .with(an_instance_of(Ci::JobArtifact))
                .and_return(double(md5_checksum: invalid_remote_checksum))
            end

            it 'counts as invalid' do
              subject.execute!(stream)

              expect(trace_metadata.checksum).to eq(src_checksum)
              expect(trace_metadata.remote_checksum).to eq(invalid_remote_checksum)
              expect(metrics)
                .to have_received(:increment_error_counter)
                .with(error_reason: :archive_invalid_checksum)
            end

            include_context 'with FIPS'
          end

          include_context 'with FIPS'
        end
      end
    end
  end

  context 'without transactional fixtures', :delete do
    let(:job) { create(:ci_build, :success, :trace_live) }
    let(:trace_metadata) { create(:ci_build_trace_metadata, build: job) }
    let(:stream) { StringIO.new('abc', 'rb') }

    describe '#execute!' do
      subject(:execute) do
        ::Gitlab::Ci::Trace::Archive.new(job, trace_metadata).execute!(stream)
      end

      before do
        stub_artifacts_object_storage(direct_upload: true)
      end

      it 'does not upload the trace inside a database transaction', :delete do
        expect(Ci::ApplicationRecord.connection.transaction_open?).to be_falsey

        allow_next_instance_of(Ci::JobArtifact) do |artifact|
          artifact.job_id = job.id
          artifact.partition_id = job.partition_id

          expect(artifact)
            .to receive(:store_file!)
            .and_wrap_original do |store_method, *args|
            expect(Ci::ApplicationRecord.connection.transaction_open?).to be_falsey

            store_method.call(*args)
          end
        end

        execute
      end
    end
  end
end
