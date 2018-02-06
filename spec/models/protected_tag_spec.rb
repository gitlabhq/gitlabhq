require 'spec_helper'

describe ProtectedTag do
  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'Validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
