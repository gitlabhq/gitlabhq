require 'spec_helper'

describe Participant do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:target) }
  end
end
