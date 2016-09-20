require 'rails_helper'

RSpec.describe Integration, type: :model do
  subject { create(:integration) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:external_token) }
  end
end
