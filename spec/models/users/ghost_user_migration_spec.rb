# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::GhostUserMigration do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:initiator_user) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:user_id) }
  end
end
