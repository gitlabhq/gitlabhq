# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_remove.html.haml' do
  describe 'render' do
    it 'enables the Remove group button for a group' do
      group = build(:group)

      render 'groups/settings/remove', group: group

      expect(rendered).to have_selector '[data-button-testid="remove-group-button"]'
      expect(rendered).not_to have_selector '[data-button-testid="remove-group-button"].disabled'
      expect(rendered).not_to have_selector '[data-testid="group-has-linked-subscription-alert"]'
    end
  end
end
