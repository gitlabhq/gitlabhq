require 'spec_helper'

describe ApproverGroup do
  subject { create(:approver_group) }

  it { should be_valid }
end
