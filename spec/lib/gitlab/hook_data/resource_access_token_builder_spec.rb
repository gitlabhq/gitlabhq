# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::ResourceAccessTokenBuilder, feature_category: :system_access do
  let_it_be(:personal_access_token) { create(:personal_access_token, user: create(:user)) }

  let(:builder) { described_class.new(personal_access_token) }

  describe '#build' do
    let(:data) { builder.build }

    it 'includes safe attributes' do
      expect(data.keys).to match_array(
        %w[
          user_id
          created_at
          id
          name
          expires_at
        ]
      )
    end
  end
end
