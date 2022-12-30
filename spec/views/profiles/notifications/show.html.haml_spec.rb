# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/notifications/show' do
  let(:groups) { GroupsFinder.new(user).execute.page(1) }
  let(:user) { create(:user) }
  let(:option_default) { _('Use primary email (%{email})') % { email: user.email } }
  let(:option_primary_email) { user.email }
  let(:expected_primary_email_attr) { "[data-emails='#{[option_primary_email].to_json}']" }
  let(:expected_default_attr) { "[data-empty-value-text='#{option_default}']" }
  let(:expected_selector) { expected_primary_email_attr + expected_default_attr + expected_value_attr }

  before do
    assign(:group_notifications, [])
    assign(:project_notifications, [])
    assign(:user, user)
    assign(:user_groups, groups)
    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive(:experiment_enabled?)
  end

  context 'when there is no database value for User#notification_email' do
    let(:expected_value_attr) { ":not([data-value])" }

    it 'displays the correct elements' do
      render

      expect(rendered).to have_selector(expected_selector)
    end
  end

  context 'when there is a database value for User#notification_email' do
    let(:expected_value_attr) { "[data-value='#{option_primary_email}']" }

    before do
      user.notification_email = option_primary_email
    end

    it 'displays the correct elements' do
      render

      expect(rendered).to have_selector(expected_selector)
    end
  end
end
