require 'rails_helper'

RSpec.describe Timelog, type: :model do
  subject { build(:timelog) }

  it { is_expected.to be_valid }

  it { is_expected.to validate_presence_of(:time_spent) }
end
