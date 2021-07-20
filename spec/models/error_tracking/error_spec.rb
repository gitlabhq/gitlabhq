# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::Error, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:events) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:actor) }
  end
end
