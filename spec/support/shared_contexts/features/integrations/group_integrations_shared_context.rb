# frozen_string_literal: true

RSpec.shared_context 'group integration activation' do
  include_context 'instance and group integration activation'

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, owner_of: group) }

  before do
    sign_in(user)
  end

  def visit_group_integrations
    visit group_settings_integrations_path(group)
  end

  def visit_group_integration(name)
    visit_group_integrations

    within('#content-body') do
      click_link(name, match: :prefer_exact)
    end
  end
end
