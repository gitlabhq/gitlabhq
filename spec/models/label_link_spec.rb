require 'spec_helper'

describe LabelLink, models: true do
  let(:label) { create(:label_link) }
  it { expect(label).to be_valid }

  it { is_expected.to belong_to(:label) }
  it { is_expected.to belong_to(:target) }
end
