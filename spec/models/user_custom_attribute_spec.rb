require 'spec_helper'

describe UserCustomAttribute do
  describe 'assocations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build :user_custom_attribute }

    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:user_id) }
  end
end
