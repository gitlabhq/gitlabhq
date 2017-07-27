require 'spec_helper'

describe ChatTeam do
  subject { create(:chat_team) }

  # Associations
  it { is_expected.to belong_to(:namespace) }

  # Validations
  it { is_expected.to validate_uniqueness_of(:namespace) }

  # Fields
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:team_id) }
end
