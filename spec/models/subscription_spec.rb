require 'spec_helper'

describe Subscription, models: true do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:subscribable) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:subscribable) }
    it { is_expected.to validate_presence_of(:user) }
  end
end
