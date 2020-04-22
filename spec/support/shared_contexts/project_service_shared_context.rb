# frozen_string_literal: true

shared_context 'project service activation' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  def visit_project_integrations
    visit project_settings_integrations_path(project)
  end

  def visit_project_integration(name)
    visit_project_integrations
    click_link(name)
  end

  def click_active_toggle
    find('input[name="service[active]"] + button').click
  end

  def click_test_integration
    click_button('Test settings and save changes')
  end

  def click_test_then_save_integration
    click_test_integration

    expect(page).to have_content('Test failed.')

    click_link('Save anyway')
  end
end
