# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::ClientKey, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:public_key) }
    it { is_expected.to validate_length_of(:public_key).is_at_most(255) }
  end

  describe '#generate_key' do
    it { expect(subject.public_key).to be_present }
    it { expect(subject.public_key).to start_with('glet_') }
  end
end
