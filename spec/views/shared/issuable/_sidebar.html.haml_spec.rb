# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/issuable/_sidebar.html.haml' do
  let_it_be(:user) { create(:user) }

  subject(:rendered) do
    render 'shared/issuable/sidebar', issuable_sidebar: IssueSerializer.new(current_user: user)
      .represent(issuable, serializer: 'sidebar'), assignees: []
  end

  context 'project in a group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:incident) { create(:incident, project: project) }

    before do
      assign(:project, project)
    end

    context 'issuable that does not support escalations' do
      let(:issuable) { incident }

      it 'shows escalation policy dropdown' do
        expect(rendered).to have_css('[data-testid="escalation_status_container"]')
      end
    end

    context 'issuable that supports escalations' do
      let(:issuable) { issue }

      it 'does not show escalation policy dropdown' do
        expect(rendered).not_to have_css('[data-testid="escalation_status_container"]')
      end
    end
  end
end
