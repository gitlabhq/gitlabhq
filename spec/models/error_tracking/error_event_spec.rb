# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::ErrorEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:error) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:occurred_at) }
  end
end
