# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_token_expiration_banner.html.haml', feature_category: :system_access do
  context 'when all conditions are true' do
    before do
      allow(view).to receive(:show_token_expiration_banner?).and_return(true)
      allow(view).to receive(:cookies).and_return({ 'hide_broadcast_message_token_expiration_banner' => nil })
    end

    it 'renders banner' do
      render 'shared/token_expiration_banner'

      expect(rendered).to have_content 'GitLab now enforces expiry dates on tokens'
    end
  end
end
