# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::ResourceAccessToken, feature_category: :system_access do
  describe '#as_json' do
    let(:token) { create(:resource_access_token, access_level: Gitlab::Access::DEVELOPER) }

    subject(:json) { described_class.new(token).as_json }

    it 'exposes the access level of the bot membership' do
      expect(json[:access_level]).to eq(Gitlab::Access::DEVELOPER)
    end

    context 'when the bot user has no membership' do
      before do
        Member.where(user_id: token.user_id).delete_all
        token.user.reload
      end

      it 'exposes a nil access level' do
        expect(json[:access_level]).to be_nil
      end
    end
  end
end
