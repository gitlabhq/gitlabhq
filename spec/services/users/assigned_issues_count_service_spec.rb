# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::AssignedIssuesCountService, :use_clean_rails_memory_store_caching,
  feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:max_limit) { 10 }

  let(:current_user) { user }

  subject { described_class.new(current_user: current_user, max_limit: max_limit) }

  it_behaves_like 'a counter caching service'

  context 'when user has assigned open issues from archived and closed projects' do
    before do
      project = create(:project, :public)
      archived_project = create(:project, :public, :archived)

      create(:issue, project: project, author: user, assignees: [user])
      create(:issue, :closed, project: project, author: user, assignees: [user])
      create(:issue, project: archived_project, author: user, assignees: [user])
    end

    it 'count all assigned open issues excluding those from closed or archived projects' do
      expect(subject.count).to eq(1)
    end
  end

  context 'when the number of assigned open issues exceeds max_limit' do
    let_it_be(:banned_user) { create(:user, :banned) }
    let_it_be(:project) { create(:project, developers: user) }

    context 'when user is admin', :enable_admin_mode do
      let_it_be(:admin) { create(:admin) }
      let_it_be(:issues) { create_list(:issue, max_limit + 1, project: project, assignees: [admin]) }
      let_it_be(:banned_issue) { create(:issue, project: project, assignees: [admin], author: banned_user) }

      let(:current_user) { admin }

      it 'returns the max_limit count' do
        expect(subject.count).to eq max_limit
      end
    end

    context 'when user is non-admin' do
      let_it_be(:issues) { create_list(:issue, max_limit + 1, project: project, assignees: [user]) }
      let_it_be(:closed_issue) { create(:issue, :closed, project: project, assignees: [user]) }
      let_it_be(:banned_issue) { create(:issue, project: project, assignees: [user], author: banned_user) }

      it 'returns the max_limit count' do
        expect(subject.count).to eq max_limit
      end
    end
  end
end
