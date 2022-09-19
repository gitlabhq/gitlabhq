# frozen_string_literal: true

RSpec.shared_examples 'a deploy token in settings' do
  it 'view deploy tokens', :js do
    user.update!(time_display_relative: true)

    visit page_path

    within('.deploy-tokens') do
      expect(page).to have_content(deploy_token.name)
      expect(page).to have_content('read_repository')
      expect(page).to have_content('read_registry')
      expect(page).to have_content('in 4 days')
    end
  end

  it 'add a new deploy token' do
    visit page_path

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

    expect(find("input#deploy_token_name").value).to eq nil
    expect(find("input#deploy_token_read_repository").checked?).to eq false
  end

  context "with form errors" do
    before do
      visit page_path
      fill_in "deploy_token_name", with: "new_deploy_key"
      fill_in "deploy_token_username", with: "deployer"
      click_button "Create deploy token"
    end

    it "shows form errors" do
      expect(page).to have_text("Scopes can't be blank")
    end

    it "keeps form inputs" do
      expect(find("input#deploy_token_name").value).to eq "new_deploy_key"
      expect(find("input#deploy_token_username").value).to eq "deployer"
    end
  end

  context 'when User#time_display_relative is false', :js do
    before do
      user.update!(time_display_relative: false)
    end

    it 'shows absolute times for expires_at' do
      visit page_path

      within('.deploy-tokens') do
        expect(page).to have_content(deploy_token.expires_at.strftime('%b %-d'))
      end
    end
  end
end
