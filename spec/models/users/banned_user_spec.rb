# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BannedUser do
  describe 'relationships' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    before do
      create(:user, :banned)
    end

    it { is_expected.to validate_presence_of(:user) }

    it 'validates uniqueness of banned user id' do
      is_expected.to validate_uniqueness_of(:user_id).with_message("banned user already exists")
    end
  end
end
