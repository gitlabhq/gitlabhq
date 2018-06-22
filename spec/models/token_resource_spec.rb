require 'spec_helper'

describe TokenResource do
  describe 'associations' do
    it { is_expected.to belong_to(:personal_access_token) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:personal_access_token) }
    it { is_expected.to validate_presence_of(:project) }
  end
end
