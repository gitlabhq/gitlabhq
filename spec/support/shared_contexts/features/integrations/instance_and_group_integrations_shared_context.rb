# frozen_string_literal: true

RSpec.shared_context 'instance and group integration activation' do
  include_context 'with integration activation'

  def click_save_integration
    click_save_changes_button
    click_save_settings_modal
  end

  def click_save_changes_button
    click_button('Save changes')
  end

  def click_save_settings_modal
    click_button('Save')
  end
end
