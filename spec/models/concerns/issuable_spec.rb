require 'spec_helper'

describe Issuable do
  let(:issuable_class) { Issue }
  let(:issue) { create(:issue) }
  let(:user) { create(:user) }

  describe "Associations" do
    subject { build(:issue) }

    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:author) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:todos).dependent(:destroy) }

    context 'Notes' do
      let!(:note) { create(:note, noteable: issue, project: issue.project) }
      let(:scoped_issue) { Issue.includes(notes: :author).find(issue.id) }

      it 'indicates if the notes have their authors loaded' do
        expect(issue.notes).not_to be_authors_loaded
        expect(scoped_issue.notes).to be_authors_loaded
      end
    end
  end

  describe 'Included modules' do
    let(:described_class) { issuable_class }

    it { is_expected.to include_module(Awardable) }
  end

  describe "Validation" do
    subject { build(:issue) }

    before do
      allow(subject).to receive(:set_iid).and_return(false)
    end

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:iid) }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }
  end

  describe "Scope" do
    subject { build(:issue) }

    it { expect(issuable_class).to respond_to(:opened) }
    it { expect(issuable_class).to respond_to(:closed) }
    it { expect(issuable_class).to respond_to(:assigned) }
  end

  describe 'author_name' do
    it 'is delegated to author' do
      expect(issue.author_name).to eq issue.author.name
    end

    it 'returns nil when author is nil' do
      issue.author_id = nil
      issue.save(validate: false)

      expect(issue.author_name).to eq nil
    end
  end

  describe ".search" do
    let!(:searchable_issue) { create(:issue, title: "Searchable issue") }

    it 'returns notes with a matching title' do
      expect(issuable_class.search(searchable_issue.title))
        .to eq([searchable_issue])
    end

    it 'returns notes with a partially matching title' do
      expect(issuable_class.search('able')).to eq([searchable_issue])
    end

    it 'returns notes with a matching title regardless of the casing' do
      expect(issuable_class.search(searchable_issue.title.upcase))
        .to eq([searchable_issue])
    end
  end

  describe ".full_search" do
    let!(:searchable_issue) do
      create(:issue, title: "Searchable issue", description: 'kittens')
    end

    it 'returns notes with a matching title' do
      expect(issuable_class.full_search(searchable_issue.title))
        .to eq([searchable_issue])
    end

    it 'returns notes with a partially matching title' do
      expect(issuable_class.full_search('able')).to eq([searchable_issue])
    end

    it 'returns notes with a matching title regardless of the casing' do
      expect(issuable_class.full_search(searchable_issue.title.upcase))
        .to eq([searchable_issue])
    end

    it 'returns notes with a matching description' do
      expect(issuable_class.full_search(searchable_issue.description))
        .to eq([searchable_issue])
    end

    it 'returns notes with a partially matching description' do
      expect(issuable_class.full_search(searchable_issue.description))
        .to eq([searchable_issue])
    end

    it 'returns notes with a matching description regardless of the casing' do
      expect(issuable_class.full_search(searchable_issue.description.upcase))
        .to eq([searchable_issue])
    end
  end

  describe '.to_ability_name' do
    it { expect(Issue.to_ability_name).to eq("issue") }
    it { expect(MergeRequest.to_ability_name).to eq("merge_request") }
  end

  describe "#today?" do
    it "returns true when created today" do
      # Avoid timezone differences and just return exactly what we want
      allow(Date).to receive(:today).and_return(issue.created_at.to_date)
      expect(issue.today?).to be_truthy
    end

    it "returns false when not created today" do
      allow(Date).to receive(:today).and_return(Date.yesterday)
      expect(issue.today?).to be_falsey
    end
  end

  describe "#new?" do
    it "returns true when created today and record hasn't been updated" do
      allow(issue).to receive(:today?).and_return(true)
      expect(issue.new?).to be_truthy
    end

    it "returns false when not created today" do
      allow(issue).to receive(:today?).and_return(false)
      expect(issue.new?).to be_falsey
    end

    it "returns false when record has been updated" do
      allow(issue).to receive(:today?).and_return(true)
      issue.touch
      expect(issue.new?).to be_falsey
    end
  end

  describe "#sort" do
    let(:project) { create(:empty_project) }

    context "by weight" do
      let!(:issue)  { create(:issue, project: project) }
      let!(:issue2) { create(:issue, weight: 1, project: project) }
      let!(:issue3) { create(:issue, weight: 2, project: project) }
      let!(:issue4) { create(:issue, weight: 3, project: project) }

      it "sorts desc" do
        issues = project.issues.sort('weight_desc')
        expect(issues).to match_array([issue4, issue3, issue2, issue])
      end

      it "sorts asc" do
        issues = project.issues.sort('weight_asc')
        expect(issues).to match_array([issue2, issue3, issue4, issue])
      end
    end

    context "by milestone due date" do
      # Correct order is:
      # Issues/MRs with milestones ordered by date
      # Issues/MRs with milestones without dates
      # Issues/MRs without milestones

      let!(:issue) { create(:issue, project: project) }
      let!(:early_milestone) { create(:milestone, project: project, due_date: 10.days.from_now) }
      let!(:late_milestone) { create(:milestone, project: project, due_date: 30.days.from_now) }
      let!(:issue1) { create(:issue, project: project, milestone: early_milestone) }
      let!(:issue2) { create(:issue, project: project, milestone: late_milestone) }
      let!(:issue3) { create(:issue, project: project) }

      it "sorts desc" do
        issues = project.issues.sort('milestone_due_desc')
        expect(issues).to match_array([issue2, issue1, issue, issue3])
      end

      it "sorts asc" do
        issues = project.issues.sort('milestone_due_asc')
        expect(issues).to match_array([issue1, issue2, issue, issue3])
      end
    end

    context 'when all of the results are level on the sort key' do
      let!(:issues) do
        10.times { create(:issue, project: project) }
      end

      it 'has no duplicates across pages' do
        sorted_issue_ids = 1.upto(10).map do |i|
          project.issues.sort('milestone_due_desc').page(i).per(1).first.id
        end

        expect(sorted_issue_ids).to eq(sorted_issue_ids.uniq)
      end
    end
  end

  describe '#subscribed?' do
    let(:project) { issue.project }

    context 'user is not a participant in the issue' do
      before do
        allow(issue).to receive(:participants).with(user).and_return([])
      end

      it 'returns false when no subcription exists' do
        expect(issue.subscribed?(user, project)).to be_falsey
      end

      it 'returns true when a subcription exists and subscribed is true' do
        issue.subscriptions.create(user: user, project: project, subscribed: true)

        expect(issue.subscribed?(user, project)).to be_truthy
      end

      it 'returns false when a subcription exists and subscribed is false' do
        issue.subscriptions.create(user: user, project: project, subscribed: false)

        expect(issue.subscribed?(user, project)).to be_falsey
      end
    end

    context 'user is a participant in the issue' do
      before do
        allow(issue).to receive(:participants).with(user).and_return([user])
      end

      it 'returns false when no subcription exists' do
        expect(issue.subscribed?(user, project)).to be_truthy
      end

      it 'returns true when a subcription exists and subscribed is true' do
        issue.subscriptions.create(user: user, project: project, subscribed: true)

        expect(issue.subscribed?(user, project)).to be_truthy
      end

      it 'returns false when a subcription exists and subscribed is false' do
        issue.subscriptions.create(user: user, project: project, subscribed: false)

        expect(issue.subscribed?(user, project)).to be_falsey
      end
    end
  end

  describe "#to_hook_data" do
    let(:data) { issue.to_hook_data(user) }
    let(:project) { issue.project }

    it "returns correct hook data" do
      expect(data[:object_kind]).to eq("issue")
      expect(data[:user]).to eq(user.hook_attrs)
      expect(data[:object_attributes]).to eq(issue.hook_attrs)
      expect(data).not_to have_key(:assignee)
    end

    context "issue is assigned" do
      before do
        issue.assignees << user
      end

      it "returns correct hook data" do
        expect(data[:assignees].first).to eq(user.hook_attrs)
      end
    end

    context "merge_request is assigned" do
      let(:merge_request) { create(:merge_request) }
      let(:data) { merge_request.to_hook_data(user) }

      before do
        merge_request.update_attribute(:assignee, user)
      end

      it "returns correct hook data" do
        expect(data[:object_attributes]['assignee_id']).to eq(user.id)
        expect(data[:assignee]).to eq(user.hook_attrs)
      end
    end

    context 'issue has labels' do
      let(:labels) { [create(:label), create(:label)] }

      before do
        issue.update_attribute(:labels, labels)
      end

      it 'includes labels in the hook data' do
        expect(data[:labels]).to eq(labels.map(&:hook_attrs))
      end
    end

    include_examples 'project hook data'
    include_examples 'deprecated repository hook data'
  end

  describe '#labels_array' do
    let(:project) { create(:empty_project) }
    let(:bug) { create(:label, project: project, title: 'bug') }
    let(:issue) { create(:issue, project: project) }

    before(:each) do
      issue.labels << bug
    end

    it 'loads the association and returns it as an array' do
      expect(issue.reload.labels_array).to eq([bug])
    end
  end

  describe '.labels_hash' do
    let(:feature_label) { create(:label, title: 'Feature') }
    let!(:issues) { create_list(:labeled_issue, 3, labels: [feature_label]) }

    it 'maps issue ids to labels titles' do
      issue_id = issues.first.id
      expect(Issue.labels_hash[issue_id]).to eq ['Feature']
    end
  end

  describe '#user_notes_count' do
    let(:project) { create(:empty_project) }
    let(:issue1) { create(:issue, project: project) }
    let(:issue2) { create(:issue, project: project) }

    before do
      create_list(:note, 3, noteable: issue1, project: project)
      create_list(:note, 6, noteable: issue2, project: project)
    end

    it 'counts the user notes' do
      expect(issue1.user_notes_count).to be(3)
      expect(issue2.user_notes_count).to be(6)
    end
  end

  describe "votes" do
    let(:project) { issue.project }

    before do
      create(:award_emoji, :upvote, awardable: issue)
      create(:award_emoji, :downvote, awardable: issue)
    end

    it "returns correct values" do
      expect(issue.upvotes).to eq(1)
      expect(issue.downvotes).to eq(1)
    end
  end

  describe '.order_due_date_and_labels_priority' do
    let(:project) { create(:empty_project) }

    def create_issue(milestone, labels)
      create(:labeled_issue, milestone: milestone, labels: labels, project: project)
    end

    it 'sorts issues in order of milestone due date, then label priority' do
      first_priority = create(:label, project: project, priority: 1)
      second_priority = create(:label, project: project, priority: 2)
      no_priority = create(:label, project: project)

      first_milestone = create(:milestone, project: project, due_date: Time.now)
      second_milestone = create(:milestone, project: project, due_date: Time.now + 1.month)
      third_milestone = create(:milestone, project: project)

      # The issues here are ordered by label priority, to ensure that we don't
      # accidentally just sort by creation date.
      second_milestone_first_priority = create_issue(second_milestone, [first_priority, second_priority, no_priority])
      third_milestone_first_priority = create_issue(third_milestone, [first_priority, second_priority, no_priority])
      first_milestone_second_priority = create_issue(first_milestone, [second_priority, no_priority])
      second_milestone_second_priority = create_issue(second_milestone, [second_priority, no_priority])
      no_milestone_second_priority = create_issue(nil, [second_priority, no_priority])
      first_milestone_no_priority = create_issue(first_milestone, [no_priority])
      second_milestone_no_labels = create_issue(second_milestone, [])
      third_milestone_no_priority = create_issue(third_milestone, [no_priority])

      result = Issue.order_due_date_and_labels_priority

      expect(result).to eq([first_milestone_second_priority,
                            first_milestone_no_priority,
                            second_milestone_first_priority,
                            second_milestone_second_priority,
                            second_milestone_no_labels,
                            third_milestone_first_priority,
                            no_milestone_second_priority,
                            third_milestone_no_priority])
    end
  end

  describe '.order_labels_priority' do
    let(:label_1) { create(:label, title: 'label_1', project: issue.project, priority: 1) }
    let(:label_2) { create(:label, title: 'label_2', project: issue.project, priority: 2) }

    subject { Issue.order_labels_priority(excluded_labels: ['label_1']).first.highest_priority }

    before do
      issue.labels << label_1
      issue.labels << label_2
    end

    it { is_expected.to eq(2) }
  end

  describe ".with_label" do
    let(:project) { create(:empty_project, :public) }
    let(:bug) { create(:label, project: project, title: 'bug') }
    let(:feature) { create(:label, project: project, title: 'feature') }
    let(:enhancement) { create(:label, project: project, title: 'enhancement') }
    let(:issue1) { create(:issue, title: "Bugfix1", project: project) }
    let(:issue2) { create(:issue, title: "Bugfix2", project: project) }
    let(:issue3) { create(:issue, title: "Feature1", project: project) }

    before(:each) do
      issue1.labels << bug
      issue1.labels << feature
      issue2.labels << bug
      issue2.labels << enhancement
      issue3.labels << feature
    end

    it 'finds the correct issue containing just enhancement label' do
      expect(Issue.with_label(enhancement.title)).to match_array([issue2])
    end

    it 'finds the correct issues containing the same label' do
      expect(Issue.with_label(bug.title)).to match_array([issue1, issue2])
    end

    it 'finds the correct issues containing only both labels' do
      expect(Issue.with_label([bug.title, enhancement.title])).to match_array([issue2])
    end
  end

  describe '#spend_time' do
    let(:user) { create(:user) }
    let(:issue) { create(:issue) }

    def spend_time(seconds)
      issue.spend_time(duration: seconds, user: user)
      issue.save!
    end

    context 'adding time' do
      it 'should update the total time spent' do
        spend_time(1800)

        expect(issue.total_time_spent).to eq(1800)
      end
    end

    context 'substracting time' do
      before do
        spend_time(1800)
      end

      it 'should update the total time spent' do
        spend_time(-900)

        expect(issue.total_time_spent).to eq(900)
      end

      context 'when time to substract exceeds the total time spent' do
        it 'raise a validation error' do
          expect do
            spend_time(-3600)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
end
