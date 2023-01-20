# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::Achievement, type: :model, feature_category: :user_profile do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }

    it { is_expected.to have_many(:user_achievements).inverse_of(:achievement) }
    it { is_expected.to have_many(:users).through(:user_achievements).inverse_of(:achievements) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Avatarable) }
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
      achievement = described_class.new(name: '  AchievementTest  ')
      achievement.valid?

      expect(achievement.name).to eq('AchievementTest')
    end
  end
end
