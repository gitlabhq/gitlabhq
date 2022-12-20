# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Timelogs::CreateService, feature_category: :team_planning do
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let(:issuable) { nil }
  let(:users_container) { project }

  describe '#execute' do
    subject { service.execute }

    context 'when issuable is an Issue' do
      let_it_be(:issuable) { create(:issue, project: project) }
      let_it_be(:note_noteable) { create(:issue, project: project) }

      it_behaves_like 'issuable supports timelog creation service'
    end

    context 'when issuable is a MergeRequest' do
      let_it_be(:issuable) { create(:merge_request, source_project: project, source_branch: 'branch-1') }
      let_it_be(:note_noteable) { create(:merge_request, source_project: project, source_branch: 'branch-2') }

      it_behaves_like 'issuable supports timelog creation service'
    end

    context 'when issuable is a WorkItem' do
      let_it_be(:issuable) { create(:work_item, project: project, title: 'WorkItem-1') }
      let_it_be(:note_noteable) { create(:work_item, project: project, title: 'WorkItem-2') }

      it_behaves_like 'issuable supports timelog creation service'
    end

    context 'when issuable is an Incident' do
      let_it_be(:issuable) { create(:incident, project: project) }
      let_it_be(:note_noteable) { create(:incident, project: project) }

      it_behaves_like 'issuable supports timelog creation service'
    end
  end
end
