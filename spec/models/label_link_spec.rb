require 'spec_helper'

describe LabelLink do
  let(:label) { create(:label_link) }
  it { label.should be_valid }

  it { should belong_to(:label) }
  it { should belong_to(:target) }
end
