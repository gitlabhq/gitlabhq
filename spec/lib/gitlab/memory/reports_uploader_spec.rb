# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::ReportsUploader, :aggregate_failures do
  let(:uploader) { described_class.new }

  let(:path) { '/report/to/upload' }

  describe '#upload' do
    # currently no-op
    it 'logs and returns false' do
      expect(Gitlab::AppLogger)
        .to receive(:info)
        .with(hash_including(:pid, :worker_id, message: "Diagnostic reports", perf_report_status: "upload requested",
                                               class: 'Gitlab::Memory::ReportsUploader', perf_report_path: path))

      expect(uploader.upload(path)).to be false
    end
  end
end
