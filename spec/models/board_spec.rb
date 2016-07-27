require 'rails_helper'

describe Board do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:lists).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end
end
