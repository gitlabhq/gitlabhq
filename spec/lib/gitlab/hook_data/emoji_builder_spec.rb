# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::EmojiBuilder, feature_category: :markdown do
  let_it_be(:award_emoji) { create(:award_emoji) }

  let(:builder) { described_class.new(award_emoji) }

  describe '#build' do
    let(:data) { builder.build }

    it 'includes safe attributes' do
      expect(data.keys).to match_array(
        %w[
          user_id
          created_at
          id
          name
          awardable_type
          awardable_id
          updated_at
        ]
      )
    end
  end
end
