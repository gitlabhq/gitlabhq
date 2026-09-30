# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/_organizations_available_alert', feature_category: :groups_and_projects do
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:user) { build_stubbed(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'when show_organizations_available_alert? is false' do
    before do
      allow(view).to receive(:show_organizations_available_alert?).with(group).and_return(false)
    end

    it 'renders nothing' do
      expect(view.render(template: 'groups/_organizations_available_alert', locals: { group: group })).to be_nil
    end
  end

  describe 'when show_organizations_available_alert? is true' do
    before do
      allow(view).to receive(:show_organizations_available_alert?).with(group).and_return(true)
    end

    it 'renders the alert' do
      render locals: { group: group }

      expect(rendered).to have_content(
        s_("Organization|Organizations bring your top-level groups, projects, and users into one place so you can " \
          "manage organization level settings and features together. Create yours to get started with features " \
          "like Artifact Central.")
      )
      expect(rendered).to have_link(
        s_('Organization|Create your organization'), href: edit_group_path(group, anchor: 'js-advanced-settings')
      )
      expect(rendered).to have_link(
        _('Learn more'),
        href: help_page_path('user/organization/_index.md', anchor: 'create-an-organization')
      )
    end
  end
end
