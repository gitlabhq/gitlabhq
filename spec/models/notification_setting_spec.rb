require 'rails_helper'

RSpec.describe NotificationSetting do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:source) }
  end

  describe "Validation" do
    subject { described_class.new(source_id: 1, source_type: 'Project') }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:level) }

    describe 'user_id' do
      before do
        subject.user = create(:user)
      end

      it { is_expected.to validate_uniqueness_of(:user_id).scoped_to([:source_type, :source_id]).with_message(/already exists in source/) }
    end

    context "events" do
      let(:user) { create(:user) }
      let(:notification_setting) { described_class.new(source_id: 1, source_type: 'Project', user_id: user.id) }

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

  describe '#event_enabled?' do
    before do
      subject.update!(user: create(:user))
    end

    context 'for an event with a matching column name' do
      it 'returns the value of the column' do
        subject.update!(new_note: true)

        expect(subject.event_enabled?(:new_note)).to be(true)
      end

      context 'when the column has a nil value' do
        it 'returns false' do
          expect(subject.event_enabled?(:new_note)).to be(false)
        end
      end
    end

    context 'for an event without a matching column name' do
      it 'returns false' do
        expect(subject.event_enabled?(:foo_event)).to be(false)
      end
    end
  end
end
