# frozen_string_literal: true

RSpec.shared_examples 'a deploy token in settings' do
  it 'view deploy tokens' do
    within('.deploy-tokens') do
      expect(page).to have_content(deploy_token.name)
      expect(page).to have_content('read_repository')
      expect(page).to have_content('read_registry')
    end
  end

  it 'add a new deploy token' do
    fill_in 'deploy_token_name', with: 'new_deploy_key'
    fill_in 'deploy_token_expires_at', with: (Date.today + 1.month).to_s
    fill_in 'deploy_token_username', with: 'deployer'
    check 'deploy_token_read_repository'
    check 'deploy_token_read_registry'
    click_button 'Create deploy token'

    expect(page).to have_content("Your new #{entity_type} deploy token has been created")

    within('.created-deploy-token-container') do
      expect(page).to have_selector("input[name='deploy-token-user'][value='deployer']")
      expect(page).to have_selector("input[name='deploy-token'][readonly='readonly']")
    end
  end
end
