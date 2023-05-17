# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'events/event/_common.html.haml' do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }

  before do
    render partial: 'events/event/common', locals: { event: event.present }
  end

  context 'when it is a work item event' do
    let_it_be(:work_item) { create(:work_item, :task, project: project) }

    let_it_be(:event) do
      create(:event, :created, project: project, target: work_item, target_type: 'WorkItem', author: user)
    end

    it 'renders the correct url with iid' do
      expect(rendered).to have_link(
        work_item.reference_link_text, href: "/#{project.full_path}/-/work_items/#{work_item.iid}"
      )
    end

    it 'uses issue_type for the target_name' do
      expect(rendered).to have_content("#{s_('Event|opened')} task #{work_item.to_reference}")
    end
  end

  context 'when it is an issue event' do
    let_it_be(:issue) { create(:issue, project: project) }

    let_it_be(:event) do
      create(:event, :created, project: project, target: issue, author: user)
    end

    it 'renders the correct url' do
      expect(rendered).to have_link(issue.reference_link_text, href: "/#{project.full_path}/-/issues/#{issue.iid}")
    end

    it 'uses issue_type for the target_name' do
      expect(rendered).to have_content("#{s_('Event|opened')} issue #{issue.to_reference}")
    end
  end
end
