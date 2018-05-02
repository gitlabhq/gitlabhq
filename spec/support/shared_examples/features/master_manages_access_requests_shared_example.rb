RSpec.shared_examples 'Master manages access requests' do
  let(:user) { create(:user) }
  let(:master) { create(:user) }

  before do
    entity.request_access(user)
    entity.respond_to?(:add_owner) ? entity.add_owner(master) : entity.add_master(master)
    sign_in(master)
  end

  it 'master can see access requests' do
    visit members_page_path

    expect_visible_access_request(entity, user)
  end

  it 'master can grant access', :js do
    visit members_page_path

    expect_visible_access_request(entity, user)

    accept_confirm { click_on 'Grant access' }

    expect_no_visible_access_request(entity, user)

    page.within('.members-list') do
      expect(page).to have_content user.name
    end
  end

  it 'master can deny access', :js do
    visit members_page_path

    expect_visible_access_request(entity, user)

    accept_confirm { click_on 'Deny access' }

    expect_no_visible_access_request(entity, user)
    expect(page).not_to have_content user.name
  end

  def expect_visible_access_request(entity, user)
    expect(entity.requesters.exists?(user_id: user)).to be_truthy
    expect(page).to have_content "Users requesting access to #{entity.name} 1"
    expect(page).to have_content user.name
  end

  def expect_no_visible_access_request(entity, user)
    expect(entity.requesters.exists?(user_id: user)).to be_falsy
    expect(page).not_to have_content "Users requesting access to #{entity.name}"
  end
end
