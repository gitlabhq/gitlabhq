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
        expect(Gitlab::Checks::FileSizeCheck::AllowExistingOversizedBlobs).not_to receive(:new)
        subject.validate!
      end
    end

    it 'checks for file sizes' do
      expect_next_instance_of(Gitlab::Checks::FileSizeCheck::AllowExistingOversizedBlobs,
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
  end
end
