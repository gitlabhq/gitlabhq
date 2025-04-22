# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::CommitsMetadata, feature_category: :code_review_workflow do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:commit_author) }
    it { is_expected.to belong_to(:committer) }
  end
end
