# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ResourceMilestoneEvents, feature_category: :team_planning do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, :public, namespace: user.namespace) }
  let!(:milestone) { create(:milestone, project: project) }

  before do
    project.add_developer(user)
  end

  context 'when eventable is an Issue' do
    it_behaves_like 'resource_milestone_events API', 'projects', 'issues', 'iid' do
      let(:parent) { project }
      let(:eventable) { create(:issue, project: project, author: user) }
    end
  end

  context 'when eventable is a Merge Request' do
    it_behaves_like 'resource_milestone_events API', 'projects', 'merge_requests', 'iid' do
      let(:parent) { project }
      let(:eventable) { create(:merge_request, source_project: project, target_project: project, author: user) }
    end
  end
end
