# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/branches/index.html.haml', feature_category: :source_code_management do
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:project, freeze: false) { create(:project, :repository) }

  let(:repository) { project.repository }
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
