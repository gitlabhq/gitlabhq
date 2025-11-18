# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/passkeys/new', feature_category: :system_access do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:user, user)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_password_required?)
    render
  end

  context 'for passkey creation' do
    it 'renders the vue container' do
      expect(rendered).to have_css('#js-passkey-registration')
    end
  end
end
