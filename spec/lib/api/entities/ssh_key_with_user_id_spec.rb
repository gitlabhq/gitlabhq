# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::SshKeyWithUserId, feature_category: :system_access do
  describe '#as_json' do
    subject { entity.as_json }

    let(:key) { create(:key, user: create(:user)) }
    let(:entity) { described_class.new(key) }

    it 'includes basic fields', :aggregate_failures do
      is_expected.to include(
        id: key.id,
        title: key.title,
        created_at: key.created_at,
        expires_at: key.expires_at,
        usage_type: 'auth_and_signing',
        last_used_at: key.last_used_at,
        user_id: key.user.id
      )
    end
  end
end
