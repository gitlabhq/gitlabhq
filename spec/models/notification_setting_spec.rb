require 'rails_helper'

RSpec.describe NotificationSetting, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:source) }
  end

  describe "Validation" do
    subject { NotificationSetting.new(source_id: 1, source_type: 'Project') }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:level) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to([:source_id, :source_type]).with_message(/already exists in source/) }

    context "events" do
      let(:user) { create(:user) }
      let(:notification_setting) { NotificationSetting.new(source_id: 1, source_type: 'Project', user_id: user.id) }

      before do
        notification_setting.level = "custom"
        notification_setting.new_note = "true"
        notification_setting.new_issue = 1
        notification_setting.close_issue = "1"
        notification_setting.merge_merge_request = "t"
        notification_setting.close_merge_request = "nil"
        notification_setting.reopen_merge_request = "false"
        notification_setting.save
      end

      it "parses boolean before saving" do
        expect(notification_setting.new_note).to eq(true)
        expect(notification_setting.new_issue).to eq(true)
        expect(notification_setting.close_issue).to eq(true)
        expect(notification_setting.merge_merge_request).to eq(true)
        expect(notification_setting.close_merge_request).to eq(false)
        expect(notification_setting.reopen_merge_request).to eq(false)
      end
    end
  end

  describe '#for_projects' do
    let(:user) { create(:user) }

    before do
      1.upto(4) do |i|
        setting = create(:notification_setting, user: user)

        setting.project.update_attributes(pending_delete: true) if i.even?
      end
    end

    it 'excludes projects pending delete' do
      expect(user.notification_settings.for_projects).to all(have_attributes(project: an_instance_of(Project)))
      expect(user.notification_settings.for_projects.map(&:project)).to all(have_attributes(pending_delete: false))
    end
  end
end
