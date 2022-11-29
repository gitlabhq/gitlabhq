# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'shared/ssh_keys/_key_delete.html.haml' do
  context 'when the icon parameter is used' do
    it 'has text' do
      render partial: 'shared/ssh_keys/key_delete', formats: :html, locals: { icon: true, button_data: '' }

      expect(rendered).not_to have_button('Delete')
      expect(rendered).to have_selector('[data-testid=remove-icon]')
    end
  end

  context 'when the icon parameter is not used' do
    it 'does not have text' do
      render partial: 'shared/ssh_keys/key_delete', formats: :html, locals: { button_data: '' }

      expect(rendered).to have_button('Delete')
      expect(rendered).not_to have_selector('[data-testid=remove-icon]')
    end
  end
end
