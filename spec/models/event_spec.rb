require 'spec_helper'

describe Event, models: true do
  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:target) }
  end

  describe "Respond to" do
    it { is_expected.to respond_to(:author_name) }
    it { is_expected.to respond_to(:author_email) }
    it { is_expected.to respond_to(:issue_title) }
    it { is_expected.to respond_to(:merge_request_title) }
    it { is_expected.to respond_to(:commits) }
  end

  describe 'Callbacks' do
    describe 'after_create :reset_project_activity' do
      let(:project) { create(:empty_project) }

      it 'calls the reset_project_activity method' do
        expect_any_instance_of(Event).to receive(:reset_project_activity)

        create_event(project, project.owner)
      end
    end
  end

  describe "Push event" do
    let(:project) { create(:project, :private) }
    let(:user) { project.owner }
    let(:event) { create_event(project, user) }

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
      subject { build(:event, action: Event::CREATED).membership_changed? }
      it { is_expected.to be_falsey }
    end

    context "updated" do
      subject { build(:event, action: Event::UPDATED).membership_changed? }
      it { is_expected.to be_falsey }
    end

    context "expired" do
      subject { build(:event, action: Event::EXPIRED).membership_changed? }
      it { is_expected.to be_truthy }
    end

    context "left" do
      subject { build(:event, action: Event::LEFT).membership_changed? }
      it { is_expected.to be_truthy }
    end

    context "joined" do
      subject { build(:event, action: Event::JOINED).membership_changed? }
      it { is_expected.to be_truthy }
    end
  end

  describe '#note?' do
    subject { Event.new(project: target.project, target: target) }

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
    let(:project) { create(:empty_project, :public) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:guest) { create(:user) }
    let(:author) { create(:author) }
    let(:assignee) { create(:user) }
    let(:admin) { create(:admin) }
    let(:issue) { create(:issue, project: project, author: author, assignee: assignee) }
    let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignee: assignee) }
    let(:note_on_commit) { create(:note_on_commit, project: project) }
    let(:note_on_issue) { create(:note_on_issue, noteable: issue, project: project) }
    let(:note_on_confidential_issue) { create(:note_on_issue, noteable: confidential_issue, project: project) }
    let(:event) { Event.new(project: project, target: target, author_id: author.id) }

    before do
      project.team << [member, :developer]
      project.team << [guest, :guest]
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
        let(:project) { create(:empty_project, :private) }

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
      subject { Event.limit_recent }

      it { is_expected.to eq([event2, event1]) }
    end

    describe 'with an explicit limit' do
      subject { Event.limit_recent(1) }

      it { is_expected.to eq([event2]) }
    end
  end

  describe '#reset_project_activity' do
    let(:project) { create(:empty_project) }

    context 'when a project was updated less than 1 hour ago' do
      it 'does not update the project' do
        project.update(last_activity_at: Time.now)

        expect(project).not_to receive(:update_column).
          with(:last_activity_at, a_kind_of(Time))

        create_event(project, project.owner)
      end
    end

    context 'when a project was updated more than 1 hour ago' do
      it 'updates the project' do
        project.update(last_activity_at: 1.year.ago)

        create_event(project, project.owner)

        project.reload

        project.last_activity_at <= 1.minute.ago
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

  def create_event(project, user, attrs = {})
    data = {
      before: Gitlab::Git::BLANK_SHA,
      after: "0220c11b9a3e6c69dc8fd35321254ca9a7b98f7e",
      ref: "refs/heads/master",
      user_id: user.id,
      user_name: user.name,
      repository: {
        name: project.name,
        url: "localhost/rubinius",
        description: "",
        homepage: "localhost/rubinius",
        private: true
      }
    }

    Event.create({
      project: project,
      action: Event::PUSHED,
      data: data,
      author_id: user.id
    }.merge!(attrs))
  end
end
