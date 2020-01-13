# frozen_string_literal: true

RSpec.shared_examples 'Maintainer manages access requests' do
  let(:user) { create(:user) }
  let(:maintainer) { create(:user) }

  before do
    entity.request_access(user)
    entity.respond_to?(:add_owner) ? entity.add_owner(maintainer) : entity.add_maintainer(maintainer)
    sign_in(maintainer)
  end

  it 'maintainer can see access requests' do
    visit members_page_path

    expect_visible_access_request(entity, user)
  end

  it 'maintainer can grant access', :js do
    visit members_page_path

    expect_visible_access_request(entity, user)

    click_on 'Grant access'

    expect_no_visible_access_request(entity, user)

    page.within('[data-qa-selector="members_list"]') do
      expect(page).to have_content user.name
    end
  end

  it 'maintainer can deny access', :js do
    visit members_page_path

    expect_visible_access_request(entity, user)

    accept_confirm { click_on 'Deny access' }

    expect_no_visible_access_request(entity, user)
    expect(page).not_to have_content user.name
  end

  def expect_visible_access_request(entity, user)
    expect(page).to have_content "Users requesting access to #{entity.name} 1"
    expect(page).to have_content user.name
  end

  def expect_no_visible_access_request(entity, user)
    expect(page).not_to have_content "Users requesting access to #{entity.name}"
  end
end
