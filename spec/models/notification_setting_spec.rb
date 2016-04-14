require 'rails_helper'

RSpec.describe NotificationSetting, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:source) }
  end

  describe "Validation" do
    subject { NotificationSetting.new(source_id: 1, source_type: 'Project') }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:level) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to([:source_id, :source_type]).with_message(/already exists in source/) }
  end
end
