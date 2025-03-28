# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::FileSizeLimitCheck, feature_category: :source_code_management do
  include_context 'changes access checks context'

  subject(:file_size_check) { described_class.new(changes_access) }

  describe '#validate!' do
    it 'does not check for file sizes' do
      expect(Gitlab::Checks::FileSizeCheck::HookEnvironmentAwareAnyOversizedBlobs).not_to receive(:new)
      expect(file_size_check.logger).not_to receive(:log_timed)
      file_size_check.validate!
    end
  end
end
