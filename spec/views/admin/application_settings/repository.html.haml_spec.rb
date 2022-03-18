# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/repository.html.haml' do
  let(:app_settings) { build(:application_setting) }
  let(:user) { create(:admin) }

  before do
    assign(:application_setting, app_settings)
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'default initial branch name' do
    it 'has the setting section' do
      render

      expect(rendered).to have_css("#js-default-branch-name")
    end

    it 'renders the correct setting section content' do
      render

      expect(rendered).to have_content("Initial default branch name")
      expect(rendered).to have_content("Set the initial name and protections for the default branch of new repositories created in the instance.")
      expect(rendered).to have_content("Initial default branch protection")
    end
  end
end
