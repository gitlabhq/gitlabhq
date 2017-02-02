require 'spec_helper'

describe ChatTeam, type: :model do
  # Associations
  it { is_expected.to belong_to(:group) }

  # Fields
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:team_id) }
end
