# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ResourceStateEvents do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public, namespace: user.namespace) }

  before do
    parent.add_developer(user)
  end

  context 'when eventable is an Issue' do
    it_behaves_like 'resource_state_events API', 'projects', 'issues', 'iid' do
      let(:parent) { project }
      let(:eventable) { create(:issue, project: project, author: user) }
    end
  end

  context 'when eventable is a Merge Request' do
    it_behaves_like 'resource_state_events API', 'projects', 'merge_requests', 'iid' do
      let(:parent) { project }
      let(:eventable) { create(:merge_request, source_project: project, target_project: project, author: user) }
    end
  end
end
