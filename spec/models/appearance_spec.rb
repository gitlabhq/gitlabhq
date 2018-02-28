require 'rails_helper'

RSpec.describe Appearance do
  subject { build(:appearance) }

  it { is_expected.to be_valid }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:description) }

  it { is_expected.to have_many(:uploads).dependent(:destroy) }
end
