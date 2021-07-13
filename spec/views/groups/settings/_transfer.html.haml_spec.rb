# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_transfer.html.haml' do
  describe 'render' do
    it 'enables the Select parent group dropdown and does not show an alert for a group' do
      group = build(:group)

      render 'groups/settings/transfer', group: group

      expect(rendered).to have_selector '[data-qa-selector="select_group_dropdown"]'
      expect(rendered).not_to have_selector '[data-qa-selector="select_group_dropdown"][disabled]'
      expect(rendered).not_to have_selector '[data-testid="group-to-transfer-has-linked-subscription-alert"]'
    end
  end
end
