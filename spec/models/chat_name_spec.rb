require 'spec_helper'

describe ChatName do
  subject { create(:chat_name) }

  it { is_expected.to belong_to(:service) }
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:service) }
  it { is_expected.to validate_presence_of(:team_id) }
  it { is_expected.to validate_presence_of(:chat_id) }

  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:service_id) }
  it { is_expected.to validate_uniqueness_of(:chat_id).scoped_to(:service_id, :team_id) }
end
