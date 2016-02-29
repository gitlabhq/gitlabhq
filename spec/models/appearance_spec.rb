require 'rails_helper'

RSpec.describe Appearance, type: :model do
  subject { create(:appearance) }

  it { is_expected.to be_valid }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:description) }
end
