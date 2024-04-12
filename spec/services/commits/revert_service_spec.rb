# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commits::RevertService, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
  end

  def revert(message: nil)
    commit = project.commit

    described_class.new(
      project,
      user,
      commit: commit,
      start_branch: project.default_branch,
      branch_name: project.default_branch,
      message: message
    ).execute
  end

  describe '#execute' do
    it 'reverts the commit from the branch' do
      result = revert
      expect(result[:status]).to eq(:success), result[:message]

      expect(project.commit.message).to include(
        "Revert \"Merge branch 'branch-merged' into '#{project.default_branch}'\""
      )
      expect(project.commit.message).to include(
        "This reverts commit b83d6e391c22777fca1ed3012fce84f633d7fed0"
      )
    end

    it 'supports a custom commit message' do
      result = revert(message: 'revert this commit')

      expect(result[:status]).to eq(:success)
      expect(project.commit.message).to eq('revert this commit')
    end
  end
end
