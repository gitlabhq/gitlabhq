# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'events/event/_common.html.haml' do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }

  context 'when it is a work item event' do
    let(:work_item) { create(:work_item, project: project) }

    let(:event) do
      create(:event, :created, project: project, target: work_item, target_type: 'WorkItem', author: user)
    end

    it 'renders the correct url' do
      render partial: 'events/event/common', locals: { event: event.present }

      expect(rendered).to have_link(
        work_item.reference_link_text, href: "/#{project.full_path}/-/work_items/#{work_item.id}"
      )
    end
  end

  context 'when it is an isssue event' do
    let(:issue) { create(:issue, project: project) }

    let(:event) do
      create(:event, :created, project: project, target: issue, author: user)
    end

    it 'renders the correct url' do
      render partial: 'events/event/common', locals: { event: event.present }

      expect(rendered).to have_link(issue.reference_link_text, href: "/#{project.full_path}/-/issues/#{issue.iid}")
    end
  end
end
