# frozen_string_literal: true

require 'spec_helper'

## this test will be removed when lib/gitlab/checks/file_size_limit_check.rb is moved to EE soon.
RSpec.describe Gitlab::Checks::FileSizeLimitCheck, feature_category: :source_code_management do
  include_context 'changes access checks context'

  subject(:file_size_check) { described_class.new(changes_access) }

  describe '#validate!' do
    it 'is a stub that does nothing' do
      expect(file_size_check.validate!).to be_nil
    end
  end
end
