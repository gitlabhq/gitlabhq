# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_token_expiration_banner.html.haml', feature_category: :system_access do
  context 'when GitLab version is >= 16.0' do
    before do
      allow(Gitlab).to receive(:version_info).and_return(Gitlab::VersionInfo.new(16, 0))
      allow(view).to receive(:cookies).and_return({ 'hide_broadcast_message_token_expiration_banner' => nil })
    end

    it 'renders banner' do
      render 'shared/token_expiration_banner', hide: false

      expect(rendered).to have_content 'GitLab now enforces expiry dates on tokens'
    end
  end

  context 'when GitLab version is <= 17.0' do
    before do
      allow(Gitlab).to receive(:version_info).and_return(Gitlab::VersionInfo.new(17, 0))
      allow(view).to receive(:cookies).and_return({ 'hide_broadcast_message_token_expiration_banner' => nil })
    end

    it 'renders banner' do
      render 'shared/token_expiration_banner', hide: false

      expect(rendered).to have_content 'GitLab now enforces expiry dates on tokens'
    end
  end
end
