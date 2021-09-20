# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/notifications/show' do
  let(:groups) { GroupsFinder.new(user).execute.page(1) }
  let(:user) { create(:user) }

  before do
    assign(:group_notifications, [])
    assign(:project_notifications, [])
    assign(:user, user)
    assign(:user_groups, groups)
    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive(:experiment_enabled?)
  end

  context 'when there is no database value for User#notification_email' do
    let(:option_default) { _('Use primary email (%{email})') % { email: user.email } }
    let(:option_primary_email) { user.email }
    let(:options) { [option_default, option_primary_email] }

    it 'displays the correct elements' do
      render

      expect(rendered).to have_select('user_notification_email', options: options, selected: nil)
    end
  end
end
