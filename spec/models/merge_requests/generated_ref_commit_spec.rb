# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::GeneratedRefCommit, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  subject(:ref_commit) do
    build(:merge_request_generated_ref_commit, project: project, merge_request: merge_request)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:commit_sha) }
  end

  describe 'factory behavior' do
    it 'is valid with valid attributes' do
      expect(ref_commit).to be_valid
    end

    it 'is not valid without a commit_sha' do
      ref_commit.commit_sha = nil
      expect(ref_commit).not_to be_valid
    end

    it 'is not valid without a project_id' do
      ref_commit.project_id = nil
      expect(ref_commit).not_to be_valid
    end

    it 'is not valid without a merge_request_id' do
      ref_commit.merge_request = nil
      expect(ref_commit).not_to be_valid
    end
  end
end
