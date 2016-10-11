require 'spec_helper'

describe LabelLink, models: true do
  it { expect(build(:label_link)).to be_valid }

  it { is_expected.to belong_to(:label) }
  it { is_expected.to belong_to(:target) }
end
