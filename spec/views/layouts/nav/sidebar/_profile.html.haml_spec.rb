# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_profile' do
  let(:user) { create(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  it_behaves_like 'has nav sidebar'
  it_behaves_like 'sidebar includes snowplow attributes', 'render', 'user_side_navigation', 'user_side_navigation'

  it 'has a link to access tokens' do
    render

    expect(rendered).to have_link(_('Access Tokens'), href: profile_personal_access_tokens_path)
  end

  context 'when personal access tokens are disabled' do
    it 'does not have a link to access tokens' do
      allow(::Gitlab::CurrentSettings).to receive_messages(personal_access_tokens_disabled?: true)

      render

      expect(rendered).not_to have_link(_('Access Tokens'), href: profile_personal_access_tokens_path)
    end
  end
end
