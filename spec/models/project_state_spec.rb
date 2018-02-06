require 'rails_helper'

describe ProjectState do
  describe 'assocations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end
end
