require 'spec_helper'

describe Label do
  let(:label) { create(:label) }
  it { label.should be_valid }

  it { should belong_to(:project) }
end
