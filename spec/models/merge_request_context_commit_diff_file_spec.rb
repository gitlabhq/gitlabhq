# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestContextCommitDiffFile do
  describe 'associations' do
    it { is_expected.to belong_to(:merge_request_context_commit) }
  end
end
