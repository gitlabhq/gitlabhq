# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::PublicGroupDetails do
  subject(:entity) { described_class.new(group) }

  let(:group) { create(:group, :with_avatar) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'includes public group fields' do
      is_expected.to eq(
        id: group.id,
        name: group.name,
        web_url: group.web_url,
        avatar_url: group.avatar_url(only_path: false),
        full_name: group.full_name,
        full_path: group.full_path
      )
    end
  end
end
