# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/_home_panel' do
  let(:group) { create(:group) }

  before do
    assign(:group, group)
  end

  context 'admin area link' do
    it 'renders admin area link for admin' do
      allow(view).to receive(:current_user).and_return(create(:admin))

      render

      expect(rendered).to have_link(href: admin_group_path(group))
    end

    it 'does not render admin area link for non-admin' do
      allow(view).to receive(:current_user).and_return(create(:user))

      render

      expect(rendered).not_to have_link(href: admin_group_path(group))
    end

    it 'does not render admin area link for anonymous' do
      allow(view).to receive(:current_user).and_return(nil)

      render

      expect(rendered).not_to have_link(href: admin_group_path(group))
    end
  end
end
