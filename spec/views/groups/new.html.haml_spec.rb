# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/new.html.haml' do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { build(:group, namespace_settings: build(:namespace_settings)) }

  before do
    assign(:group, group)
    assign(:current_user, user)

    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:captcha_required?).and_return(false)
    allow(view).to receive(:import_sources_enabled?).and_return(false)

    render
  end

  describe 'setup_for_company field' do
    it 'does not have a default selection', :aggregate_failures do
      expect(rendered).to have_field('My company or team')
      expect(rendered).not_to have_checked_field('My company or team')
      expect(rendered).to have_field('Just me')
      expect(rendered).not_to have_checked_field('Just me')
    end
  end
end
