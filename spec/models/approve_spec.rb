require 'spec_helper'

describe Approve do
  subject { create(:approve) }

  it { should be_valid }
end
