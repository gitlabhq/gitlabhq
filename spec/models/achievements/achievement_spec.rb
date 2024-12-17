# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::Achievement, type: :model, feature_category: :user_profile do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).inverse_of(:achievements).required }

    it { is_expected.to have_many(:user_achievements).inverse_of(:achievement) }
    it { is_expected.to have_many(:users).through(:user_achievements).inverse_of(:achievements) }
  end

  describe 'validations' do
    subject { create(:achievement) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to([:namespace_id]) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  end

  describe '#name' do
    it 'strips name' do
      achievement = build(:achievement, name: '  AchievementTest  ')

      achievement.valid?

      expect(achievement.name).to eq('AchievementTest')
    end
  end

  it_behaves_like Avatarable do
    let(:model) { create(:achievement, :with_avatar) }
  end

  describe '#uploads_sharding_key' do
    it 'returns namespace_id' do
      namespace = build_stubbed(:namespace)
      achievement = build_stubbed(:achievement, namespace: namespace)

      expect(achievement.uploads_sharding_key).to eq(namespace_id: namespace.id)
    end
  end
end
