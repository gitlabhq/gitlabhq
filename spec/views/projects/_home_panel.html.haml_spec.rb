require 'spec_helper'

describe 'projects/_home_panel' do
  let(:project) { create(:empty_project, :public) }

  let(:notification_settings) do
    user&.notification_settings_for(project)
  end

  before do
    assign(:project, project)
    assign(:notification_setting, notification_settings)

    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:can?).and_return(false)
  end

  context 'when user is signed in' do
    let(:user) { create(:user) }

    it 'makes it possible to set notification level' do
      render

      expect(view).to render_template('shared/notifications/_button')
      expect(rendered).to have_selector('.notification-dropdown')
    end
  end

  context 'when user is signed out' do
    let(:user) { nil }

    it 'is not possible to set notification level' do
      render

      expect(rendered).not_to have_selector('.notification_dropdown')
    end
  end
end
