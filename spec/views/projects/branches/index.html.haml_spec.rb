# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/branches/index.html.haml' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }

  let(:branches) { repository.branches }
  let(:active_branch) { branches.find { |b| b.name == 'master' } }
  let(:stale_branch) { branches.find { |b| b.name == 'feature' } }

  before do
    assign(:project, project)
    assign(:repository, repository)
    assign(:mode, 'overview')
    assign(:active_branches, [active_branch])
    assign(:stale_branches, [stale_branch])
    assign(:related_merge_requests, {})
    assign(:overview_max_branches, 5)
    assign(:branch_pipeline_statuses, {})
    assign(:refs_pipelines, {})
  end

  it 'renders list of active and stale branches' do
    content = render

    expect(content).to include(active_branch.name)
    expect(content).to include(stale_branch.name)
  end

  context 'when Gitaly is unavailable' do
    it 'renders an error' do
      assign(:gitaly_unavailable, true)

      content = render

      expect(content).to include('Unable to load branches')
      expect(content).to include(
        'The git server, Gitaly, is not available at this time. Please contact your administrator.'
      )
    end
  end
end
