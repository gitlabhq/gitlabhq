# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::RepositoryEntity, feature_category: :integrations do
  let(:update_sequence_id) { nil }

  subject do
    project = create(:project, :repository)
    commits = [project.commit]
    branches = [project.repository.find_branch('master')]
    merge_requests = [create(:merge_request, source_project: project, target_project: project)]

    described_class.represent(
      project,
      commits: commits,
      branches: branches,
      merge_requests: merge_requests,
      update_sequence_id: update_sequence_id
    ).to_json
  end

  it { is_expected.to match_schema('jira_connect/repository') }

  context 'with custom update_sequence_id' do
    let(:update_sequence_id) { 1.0 }

    it 'passes the update_sequence_id on to the nested entities', :aggregate_failures do
      parsed_subject = Gitlab::Json.parse(subject)

      expect(parsed_subject['updateSequenceId']).to eq(update_sequence_id)
      expect(parsed_subject['commits'].first['updateSequenceId']).to eq(update_sequence_id)
      expect(parsed_subject['branches'].first['updateSequenceId']).to eq(update_sequence_id)
      expect(parsed_subject['pullRequests'].first['updateSequenceId']).to eq(update_sequence_id)
    end
  end
end
