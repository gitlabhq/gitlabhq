# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::GlobalFileSizeCheck, feature_category: :source_code_management do
  include_context 'changes access checks context'

  describe '#validate!' do
    context 'when global_file_size_check is disabled' do
      before do
        stub_feature_flags(global_file_size_check: false)
      end

      it 'does not log' do
        expect(subject).not_to receive(:log_timed)
        expect(Gitlab::AppJsonLogger).not_to receive(:info)
        expect(Gitlab::Checks::FileSizeCheck::HookEnvironmentAwareAnyOversizedBlobs).not_to receive(:new)
        subject.validate!
      end
    end

    it 'checks for file sizes' do
      expect_next_instance_of(Gitlab::Checks::FileSizeCheck::HookEnvironmentAwareAnyOversizedBlobs,
        project: project,
        changes: changes,
        file_size_limit_megabytes: 100
      ) do |check|
        expect(check).to receive(:find).and_call_original
      end
      expect(subject.logger).to receive(:log_timed).with('Checking for blobs over the file size limit')
        .and_call_original
      expect(Gitlab::AppJsonLogger).to receive(:info).with('Checking for blobs over the file size limit')
      subject.validate!
    end

    context 'when there are oversized blobs' do
      let(:mock_blob_id) { "88acbfafb1b8fdb7c51db870babce21bd861ac4f" }
      let(:mock_blob_size) { 300 * 1024 * 1024 } # 300 MiB
      let(:size_msg) { "300" }
      let(:blob_double) { instance_double(Gitlab::Git::Blob, size: mock_blob_size, id: mock_blob_id) }

      before do
        allow_next_instance_of(Gitlab::Checks::FileSizeCheck::HookEnvironmentAwareAnyOversizedBlobs,
          project: project,
          changes: changes,
          file_size_limit_megabytes: 100
        ) do |check|
          allow(check).to receive(:find).and_return([blob_double])
        end
      end

      it 'logs a message with blob size and raises an exception' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with('Checking for blobs over the file size limit')
        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          message: 'Found blob over global limit',
          blob_details: [{ "id" => mock_blob_id, "size" => mock_blob_size }]
        )
        expect do
          subject.validate!
        end.to raise_exception(Gitlab::GitAccess::ForbiddenError,
          /- #{mock_blob_id} \(#{size_msg} MiB\)/)
      end
    end
  end
end
