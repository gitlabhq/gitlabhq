require 'spec_helper'

describe BroadcastMessage do
  subject { create(:broadcast_message) }

  it { should be_valid }
end
