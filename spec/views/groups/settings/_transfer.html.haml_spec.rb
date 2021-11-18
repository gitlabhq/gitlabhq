# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_transfer.html.haml' do
  describe 'render' do
    it 'enables the Select parent group dropdown and does not show an alert for a group' do
      group = build(:group)

      render 'groups/settings/transfer', group: group

      expect(rendered).to have_button 'Select parent group'
      expect(rendered).not_to have_button 'Select parent group', disabled: true
      expect(rendered).not_to have_text "This group can't be transfered because it is linked to a subscription."
    end
  end
end
