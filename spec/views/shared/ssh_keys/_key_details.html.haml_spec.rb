# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'shared/ssh_keys/_key_delete.html.haml' do
  context 'when the text parameter is used' do
    it 'has text' do
      render partial: 'shared/ssh_keys/key_delete', formats: :html, locals: { text: 'Button', html_class: '', button_data: '' }

      expect(rendered).to have_button('Button')
    end
  end

  context 'when the text parameter is not used' do
    it 'does not have text' do
      render partial: 'shared/ssh_keys/key_delete', formats: :html, locals: { html_class: '', button_data: '' }

      expect(rendered).to have_button('Delete')
    end
  end
end
