# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthenticationEvent do
  describe 'associations' do
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:user_name) }
    it { is_expected.to validate_presence_of(:result) }
  end
end
