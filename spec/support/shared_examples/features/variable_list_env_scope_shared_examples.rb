# frozen_string_literal: true

RSpec.shared_examples 'variable list env scope' do
  include ListboxHelpers

  let(:user) { create(:user) }
  let(:project) { build(:project) }
  let(:page_path) { project_settings_ci_cd_path(project) }

  before do
    sign_in(user)
    project.add_maintainer(user)

    visit page_path
    wait_for_requests
  end

  it 'adds a new variable with an environment scope' do
    open_drawer

    page.within('[data-testid="ci-variable-drawer"]') do
      fill_in 'Key', with: 'akey'
      fill_in 'Value', with: 'akey_value'

      click_button('All (default)')
      fill_in 'Search', with: 'review/*'
      find('[data-testid="create-wildcard-button"]').click

      click_button('Add variable')
    end

    wait_for_requests

    page.within('[data-testid="ci-variable-table"]') do
      expect(find('.js-ci-variable-row:first-child [data-label="Environments"]').text).to eq('review/*')
    end
  end

  it 'resets environment scope list after closing the form' do
    project.environments.create!(name: 'dev')
    project.environments.create!(name: 'env_1')
    project.environments.create!(name: 'env_2')

    open_drawer

    page.within('[data-testid="ci-variable-drawer"]') do
      click_button('All (default)')

      # default list of env scopes
      expect_env_scope_items(['*', 'dev', 'env_1', 'env_2'])

      fill_in 'Search', with: 'env'
      sleep 0.5 # wait for debounce
      wait_for_requests

      # search filters the list of env scopes
      expect_env_scope_items(%w[env_1 env_2])

      find('.gl-drawer-close-button').click
    end

    # Re-open drawer
    open_drawer

    page.within('[data-testid="ci-variable-drawer"]') do
      click_button('All (default)')

      # dropdown should reset back to default list of env scopes
      expect_env_scope_items(['*', 'dev', 'env_1', 'env_2'])
    end
  end

  private

  def open_drawer
    page.within('[data-testid="ci-variable-table"]') do
      click_button('Add variable')
      wait_for_requests
    end
  end

  def expect_env_scope_items(items)
    page.within('[data-testid="environment-scope"]') do
      expect_listbox_items(items)
    end
  end
end
