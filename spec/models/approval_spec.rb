require 'spec_helper'

describe Approval do
  subject { create(:approval) }

  it { should be_valid }
end
