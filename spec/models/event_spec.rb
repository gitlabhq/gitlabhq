require 'spec_helper'

describe Event do
  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:target) }
  end

  describe "Respond to" do
    it { is_expected.to respond_to(:author_name) }
    it { is_expected.to respond_to(:author_email) }
    it { is_expected.to respond_to(:issue_title) }
    it { is_expected.to respond_to(:merge_request_title) }
  end

  describe 'Callbacks' do
    let(:project) { create(:project) }

    describe 'after_create :reset_project_activity' do
      it 'calls the reset_project_activity method' do
        expect_any_instance_of(described_class).to receive(:reset_project_activity)

        create_push_event(project, project.owner)
      end
    end

    describe 'after_create :set_last_repository_updated_at' do
      context 'with a push event' do
        it 'updates the project last_repository_updated_at' do
          project.update(last_repository_updated_at: 1.year.ago)

          create_push_event(project, project.owner)

          project.reload

          expect(project.last_repository_updated_at).to be_within(1.minute).of(Time.now)
        end
      end

      context 'without a push event' do
        it 'does not update the project last_repository_updated_at' do
          project.update(last_repository_updated_at: 1.year.ago)

          create(:closed_issue_event, project: project, author: project.owner)

          project.reload

          expect(project.last_repository_updated_at).to be_within(1.minute).of(1.year.ago)
        end
      end
    end

    describe 'after_create :track_user_interacted_projects' do
      let(:event) { build(:push_event, project: project, author: project.owner) }

      it 'passes event to UserInteractedProject.track' do
        expect(UserInteractedProject).to receive(:available?).and_return(true)
        expect(UserInteractedProject).to receive(:track).with(event)
        event.save
      end

      it 'does not call UserInteractedProject.track if its not yet available' do
        expect(UserInteractedProject).to receive(:available?).and_return(false)
        expect(UserInteractedProject).not_to receive(:track)
        event.save
      end
    end
  end

  describe "Push event" do
    let(:project) { create(:project, :private) }
    let(:user) { project.owner }
    let(:event) { create_push_event(project, user) }

    it do
      expect(event.push?).to be_truthy
      expect(event.visible_to_user?(user)).to be_truthy
      expect(event.visible_to_user?(nil)).to be_falsey
      expect(event.tag?).to be_falsey
      expect(event.branch_name).to eq("master")
      expect(event.author).to eq(user)
    end
  end

  describe '#membership_changed?' do
    context "created" do
      subject { build(:event, :created).membership_changed? }
      it { is_expected.to be_falsey }
    end

    context "updated" do
      subject { build(:event, :updated).membership_changed? }
      it { is_expected.to be_falsey }
    end

    context "expired" do
      subject { build(:event, :expired).membership_changed? }
      it { is_expected.to be_truthy }
    end

    context "left" do
      subject { build(:event, :left).membership_changed? }
      it { is_expected.to be_truthy }
    end

    context "joined" do
      subject { build(:event, :joined).membership_changed? }
      it { is_expected.to be_truthy }
    end
  end

  describe '#note?' do
    subject { described_class.new(project: target.project, target: target) }

    context 'issue note event' do
      let(:target) { create(:note_on_issue) }

      it { is_expected.to be_note }
    end

    context 'merge request diff note event' do
      let(:target) { create(:legacy_diff_note_on_merge_request) }

      it { is_expected.to be_note }
    end
  end

  describe '#visible_to_user?' do
    let(:project) { create(:project, :public) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:guest) { create(:user) }
    let(:author) { create(:author) }
    let(:assignee) { create(:user) }
    let(:admin) { create(:admin) }
    let(:issue) { create(:issue, project: project, author: author, assignees: [assignee]) }
    let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignees: [assignee]) }
    let(:note_on_commit) { create(:note_on_commit, project: project) }
    let(:note_on_issue) { create(:note_on_issue, noteable: issue, project: project) }
    let(:note_on_confidential_issue) { create(:note_on_issue, noteable: confidential_issue, project: project) }
    let(:event) { described_class.new(project: project, target: target, author_id: author.id) }

    before do
      project.add_developer(member)
      project.add_guest(guest)
    end

    context 'commit note event' do
      let(:target) { note_on_commit }

      it do
        aggregate_failures do
          expect(event.visible_to_user?(non_member)).to eq true
          expect(event.visible_to_user?(member)).to eq true
          expect(event.visible_to_user?(guest)).to eq true
          expect(event.visible_to_user?(admin)).to eq true
        end
      end

      context 'private project' do
        let(:project) { create(:project, :private) }

        it do
          aggregate_failures do
            expect(event.visible_to_user?(non_member)).to eq false
            expect(event.visible_to_user?(member)).to eq true
            expect(event.visible_to_user?(guest)).to eq false
            expect(event.visible_to_user?(admin)).to eq true
          end
        end
      end
    end

    context 'issue event' do
      context 'for non confidential issues' do
        let(:target) { issue }

        it do
          expect(event.visible_to_user?(non_member)).to eq true
          expect(event.visible_to_user?(author)).to eq true
          expect(event.visible_to_user?(assignee)).to eq true
          expect(event.visible_to_user?(member)).to eq true
          expect(event.visible_to_user?(guest)).to eq true
          expect(event.visible_to_user?(admin)).to eq true
        end
      end

      context 'for confidential issues' do
        let(:target) { confidential_issue }

        it do
          expect(event.visible_to_user?(non_member)).to eq false
          expect(event.visible_to_user?(author)).to eq true
          expect(event.visible_to_user?(assignee)).to eq true
          expect(event.visible_to_user?(member)).to eq true
          expect(event.visible_to_user?(guest)).to eq false
          expect(event.visible_to_user?(admin)).to eq true
        end
      end
    end

    context 'issue note event' do
      context 'on non confidential issues' do
        let(:target) { note_on_issue }

        it do
          expect(event.visible_to_user?(non_member)).to eq true
          expect(event.visible_to_user?(author)).to eq true
          expect(event.visible_to_user?(assignee)).to eq true
          expect(event.visible_to_user?(member)).to eq true
          expect(event.visible_to_user?(guest)).to eq true
          expect(event.visible_to_user?(admin)).to eq true
        end
      end

      context 'on confidential issues' do
        let(:target) { note_on_confidential_issue }

        it do
          expect(event.visible_to_user?(non_member)).to eq false
          expect(event.visible_to_user?(author)).to eq true
          expect(event.visible_to_user?(assignee)).to eq true
          expect(event.visible_to_user?(member)).to eq true
          expect(event.visible_to_user?(guest)).to eq false
          expect(event.visible_to_user?(admin)).to eq true
        end
      end
    end

    context 'merge request diff note event' do
      let(:project) { create(:project, :public) }
      let(:merge_request) { create(:merge_request, source_project: project, author: author, assignee: assignee) }
      let(:note_on_merge_request) { create(:legacy_diff_note_on_merge_request, noteable: merge_request, project: project) }
      let(:target) { note_on_merge_request }

      it do
        expect(event.visible_to_user?(non_member)).to eq true
        expect(event.visible_to_user?(author)).to eq true
        expect(event.visible_to_user?(assignee)).to eq true
        expect(event.visible_to_user?(member)).to eq true
        expect(event.visible_to_user?(guest)).to eq true
        expect(event.visible_to_user?(admin)).to eq true
      end

      context 'private project' do
        let(:project) { create(:project, :private) }

        it do
          expect(event.visible_to_user?(non_member)).to eq false
          expect(event.visible_to_user?(author)).to eq true
          expect(event.visible_to_user?(assignee)).to eq true
          expect(event.visible_to_user?(member)).to eq true
          expect(event.visible_to_user?(guest)).to eq false
          expect(event.visible_to_user?(admin)).to eq true
        end
      end
    end
  end

  describe '.limit_recent' do
    let!(:event1) { create(:closed_issue_event) }
    let!(:event2) { create(:closed_issue_event) }

    describe 'without an explicit limit' do
      subject { described_class.limit_recent }

      it { is_expected.to eq([event2, event1]) }
    end

    describe 'with an explicit limit' do
      subject { described_class.limit_recent(1) }

      it { is_expected.to eq([event2]) }
    end
  end

  describe '#reset_project_activity' do
    let(:project) { create(:project) }

    context 'when a project was updated less than 1 hour ago' do
      it 'does not update the project' do
        project.update(last_activity_at: Time.now)

        expect(project).not_to receive(:update_column)
          .with(:last_activity_at, a_kind_of(Time))

        create_push_event(project, project.owner)
      end
    end

    context 'when a project was updated more than 1 hour ago' do
      it 'updates the project' do
        project.update(last_activity_at: 1.year.ago)

        create_push_event(project, project.owner)

        project.reload

        expect(project.last_activity_at).to be_within(1.minute).of(Time.now)
      end
    end
  end

  describe '#authored_by?' do
    let(:event) { build(:event) }

    it 'returns true when the event author and user are the same' do
      expect(event.authored_by?(event.author)).to eq(true)
    end

    it 'returns false when passing nil as an argument' do
      expect(event.authored_by?(nil)).to eq(false)
    end

    it 'returns false when the given user is not the author of the event' do
      user = double(:user, id: -1)

      expect(event.authored_by?(user)).to eq(false)
    end
  end

  describe '#body?' do
    let(:push_event) do
      event = build(:push_event)

      allow(event).to receive(:push?).and_return(true)

      event
    end

    it 'returns true for a push event with commits' do
      allow(push_event).to receive(:push_with_commits?).and_return(true)

      expect(push_event).to be_body
    end

    it 'returns false for a push event without a valid commit range' do
      allow(push_event).to receive(:push_with_commits?).and_return(false)

      expect(push_event).not_to be_body
    end

    it 'returns true for a Note event' do
      event = build(:event)

      allow(event).to receive(:note?).and_return(true)

      expect(event).to be_body
    end

    it 'returns true if the target responds to #title' do
      event = build(:event)

      allow(event).to receive(:target).and_return(double(:target, title: 'foo'))

      expect(event).to be_body
    end

    it 'returns false for a regular event without a target' do
      event = build(:event)

      expect(event).not_to be_body
    end
  end

  describe '#target' do
    it 'eager loads the author of an event target' do
      create(:closed_issue_event)

      events = described_class.preload(:target).all.to_a
      count = ActiveRecord::QueryRecorder
        .new { events.first.target.author }.count

      # This expectation exists to make sure the test doesn't pass when the
      # author is for some reason not loaded at all.
      expect(events.first.target.author).to be_an_instance_of(User)

      expect(count).to be_zero
    end
  end

  def create_push_event(project, user)
    event = create(:push_event, project: project, author: user)

    create(:push_event_payload,
           event: event,
           commit_to: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
           commit_count: 0,
           ref: 'master')

    event
  end
end
