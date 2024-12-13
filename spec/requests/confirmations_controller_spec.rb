# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConfirmationsController, type: :request, feature_category: :system_access do
  describe '#show' do
    let_it_be_with_reload(:user) { create(:user, :unconfirmed) }
    let(:expected_context) do
      { 'meta.caller_id' => 'ConfirmationsController#show',
        'meta.user' => user.username }
    end

    subject(:perform_request) do
      get user_confirmation_path, params: { confirmation_token: user.confirmation_token }
    end

    before do
      allow(Gitlab::AppLogger).to receive(:info)
    end

    include_examples 'set_current_context'
  end
end
