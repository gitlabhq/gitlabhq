# frozen_string_literal: true

RSpec.shared_context 'project integration activation' do
  include_context 'with integration activation'

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  def visit_project_integrations
    visit project_settings_integrations_path(project)
  end

  def visit_project_integration(name)
    visit_project_integrations

    within('#content-body') do
      click_link(name, match: :prefer_exact)
    end
  end

  def click_save_integration
    click_button('Save changes')
  end

  def click_test_integration
    click_button('Test settings')
  end

  def click_test_then_save_integration(expect_test_to_fail: true)
    click_test_integration

    if expect_test_to_fail
      expect(page).to have_content('Connection failed.')
    else
      expect(page).to have_content('Connection successful.')
    end

    click_save_integration
  end
end
