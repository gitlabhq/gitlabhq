# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojis::BaseService, feature_category: :team_planning do
  let(:awardable) { build(:note) }
  let(:current_user) { build(:user) }

  describe '.initialize' do
    subject { described_class }

    it 'uses same emoji name if not an alias' do
      emoji_name = 'horse'

      expect(subject.new(awardable, emoji_name, current_user).name).to eq(emoji_name)
    end

    it 'uses emoji original name if its an alias' do
      emoji_alias = 'small_airplane'
      emoji_name = 'airplane_small'

      expect(subject.new(awardable, emoji_alias, current_user).name).to eq(emoji_name)
    end
  end
end
