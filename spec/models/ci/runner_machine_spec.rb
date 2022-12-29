# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerMachine, feature_category: :runner_fleet, type: :model do
  it_behaves_like 'having unique enum values'

  it { is_expected.to belong_to(:runner) }

  describe 'validation' do
    it { is_expected.to validate_presence_of(:runner) }
    it { is_expected.to validate_presence_of(:machine_xid) }
    it { is_expected.to validate_length_of(:machine_xid).is_at_most(64) }
    it { is_expected.to validate_length_of(:version).is_at_most(2048) }
    it { is_expected.to validate_length_of(:revision).is_at_most(255) }
    it { is_expected.to validate_length_of(:platform).is_at_most(255) }
    it { is_expected.to validate_length_of(:architecture).is_at_most(255) }
    it { is_expected.to validate_length_of(:ip_address).is_at_most(1024) }
  end
end
