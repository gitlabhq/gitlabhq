# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::FeatureSetting do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
  end
end
