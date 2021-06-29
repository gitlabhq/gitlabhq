# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationSetting do
  it_behaves_like 'having unique enum values'

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
        expect(notification_setting.close_merge_request).to eq(true)
        expect(notification_setting.reopen_merge_request).to eq(false)
      end
    end

    context 'notification_email' do
      let_it_be(:user) { create(:user) }

      subject { described_class.new(source_id: 1, source_type: 'Project', user_id: user.id) }

      it 'allows to change email to verified one' do
        email = create(:email, :confirmed, user: user)

        subject.update(notification_email: email.email)

        expect(subject).to be_valid
      end

      it 'does not allow to change email to not verified one' do
        email = create(:email, user: user)

        subject.update(notification_email: email.email)

        expect(subject).to be_invalid
      end

      it 'allows to change email to empty one' do
        subject.update(notification_email: '')

        expect(subject).to be_valid
      end
    end
  end

  describe '#for_projects' do
    let(:user) { create(:user) }

    before do
      1.upto(4) do |i|
        setting = create(:notification_setting, user: user)

        setting.project.update(pending_delete: true) if i.even?
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

    describe 'for failed_pipeline' do
      using RSpec::Parameterized::TableSyntax

      where(:column, :expected) do
        nil | true
        true | true
        false | false
      end

      with_them do
        before do
          subject.update!(failed_pipeline: column)
        end

        it do
          expect(subject.event_enabled?(:failed_pipeline)).to eq(expected)
        end
      end
    end

    describe 'for fixed_pipeline' do
      using RSpec::Parameterized::TableSyntax

      where(:column, :expected) do
        nil | true
        true | true
        false | false
      end

      with_them do
        before do
          subject.update!(fixed_pipeline: column)
        end

        it do
          expect(subject.event_enabled?(:fixed_pipeline)).to eq(expected)
        end
      end
    end
  end

  describe '.email_events' do
    subject { described_class.email_events }

    it 'returns email events' do
      expect(subject).to include(
        :new_release,
        :new_note,
        :new_issue,
        :reopen_issue,
        :close_issue,
        :reassign_issue,
        :new_merge_request,
        :reopen_merge_request,
        :close_merge_request,
        :reassign_merge_request,
        :change_reviewer_merge_request,
        :merge_merge_request,
        :failed_pipeline,
        :success_pipeline,
        :fixed_pipeline,
        :moved_project,
        :merge_when_pipeline_succeeds
      )
    end

    it 'includes EXCLUDED_WATCHER_EVENTS' do
      expect(subject).to include(*described_class::EXCLUDED_WATCHER_EVENTS)
    end
  end

  describe '#email_events' do
    let(:source) { build(:group) }

    subject { build(:notification_setting, source: source) }

    it 'calls email_events' do
      expect(described_class).to receive(:email_events).with(source)
      subject.email_events
    end
  end

  describe '#order_by_id_asc' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:notification_setting_1) { create(:notification_setting, project: project) }
    let_it_be(:notification_setting_2) { create(:notification_setting, project: other_project) }
    let_it_be(:notification_setting_3) { create(:notification_setting, project: project) }

    let(:ids) { [notification_setting_1, notification_setting_2, notification_setting_3].map(&:id) }

    subject(:ordered_records) { described_class.where(id: ids, source: project).order_by_id_asc }

    it { is_expected.to eq([notification_setting_1, notification_setting_3]) }
  end
end
