require 'spec_helper'

describe ForkNetworkMember do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:fork_network) }
  end
end
