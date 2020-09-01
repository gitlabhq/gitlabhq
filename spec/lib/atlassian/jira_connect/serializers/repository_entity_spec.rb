# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::RepositoryEntity do
  subject do
    project = create(:project, :repository)
    commits = [project.commit]
    branches = [project.repository.find_branch('master')]
    merge_requests = [create(:merge_request, source_project: project, target_project: project)]

    described_class.represent(
      project,
      commits: commits,
      branches: branches,
      merge_requests: merge_requests
    ).to_json
  end

  it { is_expected.to match_schema('jira_connect/repository') }
end
