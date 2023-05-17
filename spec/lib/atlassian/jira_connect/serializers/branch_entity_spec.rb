# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::BranchEntity, feature_category: :integrations do
  include AfterNextHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:branch) { project.repository.find_branch('improve/awesome') }

  subject { described_class.represent(branch, project: project).as_json }

  it 'sets the hash of the branch name as the id' do
    expect(subject[:id]).to eq('bbfba9b197ace5da93d03382a7ce50081ae89d99faac1f2326566941288871ce')
  end

  describe '#issue_keys' do
    it 'calls Atlassian::JiraIssueKeyExtractors::Branch#issue_keys' do
      expect_next(Atlassian::JiraIssueKeyExtractors::Branch) do |extractor|
        expect(extractor).to receive(:issue_keys)
      end

      subject
    end

    it 'avoids N+1 queries when fetching merge requests for multiple branches' do
      master_branch = project.repository.find_branch('master')

      create(
        :merge_request,
        source_project: project,
        source_branch: 'improve/awesome',
        title: 'OPEN_MR_TITLE-1',
        description: 'OPEN_MR_DESC-1'
      )

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { subject }

      create(
        :merge_request,
        source_project: project,
        source_branch: 'master',
        title: 'MASTER_MR_TITLE-1',
        description: 'MASTER_MR_DESC-1'
      )

      expect(subject).to include(
        name: 'improve/awesome',
        issueKeys: match_array(%w[OPEN_MR_TITLE-1 OPEN_MR_DESC-1])
      )

      expect do
        expect(described_class.represent([branch, master_branch], project: project).as_json).to contain_exactly(
          hash_including(name: 'improve/awesome', issueKeys: match_array(%w[BRANCH-1 OPEN_MR_TITLE-1 OPEN_MR_DESC-1])),
          hash_including(name: 'master', issueKeys: match_array(%w[MASTER_MR_TITLE-1 MASTER_MR_DESC-1]))
        )
      end.not_to exceed_query_limit(control)
    end
  end
end
