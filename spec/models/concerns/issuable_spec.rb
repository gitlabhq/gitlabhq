# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable, feature_category: :team_planning do
  include ProjectForksHelper
  using RSpec::Parameterized::TableSyntax

  let(:issuable_class) { Issue }
  let(:issue) { create(:issue, title: 'An issue', description: 'A description') }
  let(:user) { create(:user) }

  describe "Associations" do
    subject { build(:issue) }

    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:author) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:todos) }
    it { is_expected.to have_many(:labels) }

    context 'Notes' do
      let!(:note) { create(:note, noteable: issue, project: issue.project) }
      let(:scoped_issue) { Issue.includes(notes: :author).find(issue.id) }

      it 'indicates if the notes have their authors loaded' do
        expect(issue.notes).not_to be_authors_loaded
        expect(scoped_issue.notes).to be_authors_loaded
      end

      describe 'note_authors' do
        it { is_expected.to have_many(:note_authors).through(:notes) }
      end

      describe 'user_note_authors' do
        let_it_be(:system_user) { create(:user) }

        let!(:system_note) { create(:system_note, author: system_user, noteable: issue, project: issue.project) }

        it 'filters the authors to those of user notes' do
          authors = issue.user_note_authors

          expect(authors).to include(note.author)
          expect(authors).not_to include(system_user)
        end
      end
    end
  end

  describe 'Included modules' do
    let(:described_class) { issuable_class }

    it { is_expected.to include_module(Awardable) }
  end

  describe "Validation" do
    context 'general validations' do
      subject { build(:issue) }

      before do
        allow(InternalId).to receive(:generate_next).and_return(nil)
      end

      it { is_expected.to validate_presence_of(:project) }
      it { is_expected.to validate_presence_of(:author) }
      it { is_expected.to validate_presence_of(:title) }
      it { is_expected.to validate_length_of(:title).is_at_most(described_class::TITLE_LENGTH_MAX) }

      it_behaves_like 'validates description length with custom validation' do
        before do
          allow(InternalId).to receive(:generate_next).and_call_original
        end
      end

      it_behaves_like 'truncates the description to its allowed maximum length on import'
    end

    describe '#validate_assignee_length' do
      let(:assignee_1) { create(:user) }
      let(:assignee_2) { create(:user) }
      let(:assignee_3) { create(:user) }

      subject { create(:merge_request) }

      before do
        stub_const("Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS", 2)
      end

      it 'will not exceed the assignee limit' do
        expect do
          subject.update!(assignees: [assignee_1, assignee_2, assignee_3])
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "Scope" do
    it { expect(issuable_class).to respond_to(:opened) }
    it { expect(issuable_class).to respond_to(:closed) }
    it { expect(issuable_class).to respond_to(:assigned) }

    describe '.includes_for_bulk_update' do
      before do
        stub_const('Example', Class.new(ActiveRecord::Base))

        Example.class_eval do
          include Issuable # adds :labels, among others

          belongs_to :author
          has_many :assignees
          has_one :metrics
        end
      end

      it 'includes available associations' do
        expect(Example.includes_for_bulk_update.includes_values).to eq([:author, :assignees, :labels, :metrics])
      end
    end
  end

  describe 'author_name' do
    it 'is delegated to author' do
      expect(issue.author_name).to eq issue.author.name
    end

    it 'returns nil when author is nil' do
      issue.author_id = nil
      issue.save!(validate: false)

      expect(issue.author_name).to eq nil
    end
  end

  describe '.initialize' do
    it 'maps the state to the right state_id' do
      described_class::STATE_ID_MAP.each do |key, value|
        issuable = MergeRequest.new(state: key)

        expect(issuable.state).to eq(key)
        expect(issuable.state_id).to eq(value)
      end
    end

    it 'maps a string version of the state to the right state_id' do
      described_class::STATE_ID_MAP.each do |key, value|
        issuable = MergeRequest.new('state' => key)

        expect(issuable.state).to eq(key)
        expect(issuable.state_id).to eq(value)
      end
    end

    it 'gives preference to state_id if present' do
      issuable = MergeRequest.new(
        'state' => 'opened',
        'state_id' => described_class::STATE_ID_MAP['merged']
      )

      expect(issuable.state).to eq('merged')
      expect(issuable.state_id).to eq(described_class::STATE_ID_MAP['merged'])
    end
  end

  describe '.any_label' do
    let_it_be(:issue_with_label) { create(:labeled_issue, labels: [create(:label)]) }
    let_it_be(:issue_with_multiple_labels) { create(:labeled_issue, labels: create_list(:label, 2)) }
    let_it_be(:issue_without_label) { create(:issue) }

    it 'returns an issuable with at least one label' do
      expect(issuable_class.any_label).to match_array([issue_with_label, issue_with_multiple_labels])
    end

    context 'for custom sorting' do
      it 'returns an issuable with at least one label' do
        expect(issuable_class.any_label('created_at')).to eq([issue_with_label, issue_with_multiple_labels])
      end
    end
  end

  describe ".search" do
    let!(:searchable_issue) { create(:issue, title: "Searchable awesome issue") }
    let!(:searchable_issue2) { create(:issue, title: 'Aw') }

    it 'returns issues with a matching title' do
      expect(issuable_class.search(searchable_issue.title))
        .to eq([searchable_issue])
    end

    it 'returns issues with a partially matching title' do
      expect(issuable_class.search('able')).to eq([searchable_issue])
    end

    it 'returns issues with a matching title regardless of the casing' do
      expect(issuable_class.search(searchable_issue.title.upcase))
        .to eq([searchable_issue])
    end

    it 'returns issues with a fuzzy matching title' do
      expect(issuable_class.search('searchable issue')).to eq([searchable_issue])
    end

    it 'returns issues with a matching title for a query shorter than 3 chars' do
      expect(issuable_class.search(searchable_issue2.title.downcase)).to eq([searchable_issue2])
    end
  end

  describe ".full_search" do
    let!(:searchable_issue) do
      create(:issue, title: "Searchable awesome issue", description: 'Many cute kittens')
    end

    let!(:searchable_issue2) { create(:issue, title: "Aw", description: "Cu") }

    it 'returns issues with a matching title' do
      expect(issuable_class.full_search(searchable_issue.title))
        .to eq([searchable_issue])
    end

    it 'returns issues with a partially matching title' do
      expect(issuable_class.full_search('able')).to eq([searchable_issue])
    end

    it 'returns issues with a matching title regardless of the casing' do
      expect(issuable_class.full_search(searchable_issue.title.upcase))
        .to eq([searchable_issue])
    end

    it 'returns issues with a fuzzy matching title' do
      expect(issuable_class.full_search('searchable issue')).to eq([searchable_issue])
    end

    it 'returns issues with a matching description' do
      expect(issuable_class.full_search(searchable_issue.description))
        .to eq([searchable_issue])
    end

    it 'returns issues with a partially matching description' do
      expect(issuable_class.full_search('cut')).to eq([searchable_issue])
    end

    it 'returns issues with a matching description regardless of the casing' do
      expect(issuable_class.full_search(searchable_issue.description.upcase))
        .to eq([searchable_issue])
    end

    it 'returns issues with a fuzzy matching description' do
      expect(issuable_class.full_search('many kittens')).to eq([searchable_issue])
    end

    it 'returns issues with a matching description for a query shorter than 3 chars' do
      expect(issuable_class.full_search(searchable_issue2.description.downcase)).to eq([searchable_issue2])
    end

    it 'returns issues with a fuzzy matching description for a query shorter than 3 chars if told to do so' do
      search = searchable_issue2.description.downcase.scan(/\w+/).sample[-1]

      expect(issuable_class.full_search(search, use_minimum_char_limit: false)).to include(searchable_issue2)
    end

    it 'returns issues with a fuzzy matching title for a query shorter than 3 chars if told to do so' do
      expect(issuable_class.full_search('i', use_minimum_char_limit: false)).to include(searchable_issue)
    end

    context 'when matching columns is "title"' do
      it 'returns issues with a matching title' do
        expect(issuable_class.full_search(searchable_issue.title, matched_columns: 'title'))
          .to eq([searchable_issue])
      end

      it 'returns no issues with a matching description' do
        expect(issuable_class.full_search(searchable_issue.description, matched_columns: 'title'))
          .to be_empty
      end
    end

    context 'when matching columns is "description"' do
      it 'returns no issues with a matching title' do
        expect(issuable_class.full_search(searchable_issue.title, matched_columns: 'description'))
          .to be_empty
      end

      it 'returns issues with a matching description' do
        expect(issuable_class.full_search(searchable_issue.description, matched_columns: 'description'))
          .to eq([searchable_issue])
      end
    end

    context 'when matching columns is "title,description"' do
      it 'returns issues with a matching title' do
        expect(issuable_class.full_search(searchable_issue.title, matched_columns: 'title,description'))
          .to eq([searchable_issue])
      end

      it 'returns issues with a matching description' do
        expect(issuable_class.full_search(searchable_issue.description, matched_columns: 'title,description'))
          .to eq([searchable_issue])
      end
    end

    context 'when matching columns is nil"' do
      it 'returns issues with a matching title' do
        expect(issuable_class.full_search(searchable_issue.title, matched_columns: nil))
          .to eq([searchable_issue])
      end

      it 'returns issues with a matching description' do
        expect(issuable_class.full_search(searchable_issue.description, matched_columns: nil))
          .to eq([searchable_issue])
      end
    end

    context 'when matching columns is "invalid"' do
      it 'returns issues with a matching title' do
        expect(issuable_class.full_search(searchable_issue.title, matched_columns: 'invalid'))
          .to eq([searchable_issue])
      end

      it 'returns issues with a matching description' do
        expect(issuable_class.full_search(searchable_issue.description, matched_columns: 'invalid'))
          .to eq([searchable_issue])
      end
    end

    context 'when matching columns is "title,invalid"' do
      it 'returns issues with a matching title' do
        expect(issuable_class.full_search(searchable_issue.title, matched_columns: 'title,invalid'))
          .to eq([searchable_issue])
      end

      it 'returns no issues with a matching description' do
        expect(issuable_class.full_search(searchable_issue.description, matched_columns: 'title,invalid'))
          .to be_empty
      end
    end
  end

  describe '.gfm_autocomplete_search' do
    let_it_be(:project) { create(:project) }

    let_it_be(:issue_1) { create(:issue, project: project, iid: 1, title: 'gitlab 2') }
    let_it_be(:issue_10) { create(:issue, project: project, iid: 10, title: 'some gitlab issue') }
    let_it_be(:issue_20) { create(:issue, project: project, iid: 20, title: 'other title') }

    it 'returns issuables with matching iid or title ordered by id desc' do
      expect(issuable_class.gfm_autocomplete_search('2')).to eq([issue_20, issue_1])
    end

    it 'returns issuables with matching title ordered by id desc' do
      expect(issuable_class.gfm_autocomplete_search('gitlab')).to eq([issue_10, issue_1])
    end

    it 'allows partial string matches' do
      expect(issuable_class.gfm_autocomplete_search('the')).to eq([issue_20])
    end
  end

  describe '.to_ability_name' do
    it { expect(Issue.to_ability_name).to eq("issue") }
    it { expect(MergeRequest.to_ability_name).to eq("merge_request") }
  end

  describe "#sort_by_attribute" do
    let(:project) { create(:project) }

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
        issues = project.issues.sort_by_attribute('milestone_due_desc')
        expect(issues).to match_array([issue2, issue1, issue, issue3])
      end

      it "sorts asc" do
        issues = project.issues.sort_by_attribute('milestone_due_asc')
        expect(issues).to match_array([issue1, issue2, issue, issue3])
      end
    end

    context 'when all of the results are level on the sort key' do
      let!(:issues) do
        create_list(:issue, 10, project: project)
      end

      it 'has no duplicates across pages' do
        sorted_issue_ids = 1.upto(10).map do |i|
          project.issues.sort_by_attribute('milestone_due_desc').page(i).per(1).first.id
        end

        expect(sorted_issue_ids).to eq(sorted_issue_ids.uniq)
      end
    end

    context 'by title' do
      let!(:issue1) { create(:issue, project: project, title: 'foo') }
      let!(:issue2) { create(:issue, project: project, title: 'bar') }
      let!(:issue3) { create(:issue, project: project, title: 'baz') }
      let!(:issue4) { create(:issue, project: project, title: 'Baz 2') }

      it 'sorts asc' do
        issues = project.issues.sort_by_attribute('title_asc')
        expect(issues).to eq([issue2, issue3, issue4, issue1])
      end

      it 'sorts desc' do
        issues = project.issues.sort_by_attribute('title_desc')
        expect(issues).to eq([issue1, issue4, issue3, issue2])
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
        issue.subscriptions.create!(user: user, project: project, subscribed: true)

        expect(issue.subscribed?(user, project)).to be_truthy
      end

      it 'returns false when a subcription exists and subscribed is false' do
        issue.subscriptions.create!(user: user, project: project, subscribed: false)

        expect(issue.subscribed?(user, project)).to be_falsey
      end
    end

    context 'user is a participant in the issue' do
      before do
        allow(issue).to receive(:participant?).with(user).and_return(true)
      end

      it 'returns false when no subcription exists' do
        expect(issue.subscribed?(user, project)).to be_truthy
      end

      it 'returns true when a subcription exists and subscribed is true' do
        issue.subscriptions.create!(user: user, project: project, subscribed: true)

        expect(issue.subscribed?(user, project)).to be_truthy
      end

      it 'returns false when a subcription exists and subscribed is false' do
        issue.subscriptions.create!(user: user, project: project, subscribed: false)

        expect(issue.subscribed?(user, project)).to be_falsey
      end
    end
  end

  describe '#time_estimate=' do
    it 'coerces the value below Gitlab::Database::MAX_INT_VALUE' do
      expect { issue.time_estimate = 100 }.to change { issue.time_estimate }.to(100)
      expect { issue.time_estimate = Gitlab::Database::MAX_INT_VALUE + 100 }.to change { issue.time_estimate }.to(Gitlab::Database::MAX_INT_VALUE)
    end

    it 'skips coercion for not Integer values' do
      expect { issue.time_estimate = nil }.to change { issue.read_attribute(:time_estimate) }.to(nil)
      expect { issue.time_estimate = 'invalid time' }.not_to raise_error
      expect { issue.time_estimate = 22.33 }.not_to raise_error
    end
  end

  describe '#to_hook_data' do
    let(:builder) { double }

    context 'when old_associations is empty' do
      let(:label) { create(:label) }

      before do
        issue.update!(labels: [label])
        issue.assignees << user
        issue.spend_time(duration: 2, user_id: user.id, spent_at: Time.current)
        expect(Gitlab::DataBuilder::Issuable)
          .to receive(:new).with(issue).and_return(builder)
      end

      it 'delegates to Gitlab::DataBuilder::Issuable#build and does not set labels, assignees, nor total_time_spent' do
        expect(builder).to receive(:build).with(
          user: user,
          changes: hash_not_including(:total_time_spent, :labels, :assignees),
          action: 'open')

        # In some cases, old_associations is empty, e.g. on a close event
        issue.to_hook_data(user, action: 'open')
      end
    end

    context 'labels are updated' do
      let(:labels) { create_list(:label, 2) }

      before do
        issue.update!(labels: [labels[1]])
        expect(Gitlab::DataBuilder::Issuable)
          .to receive(:new).with(issue).and_return(builder)
      end

      it 'delegates to Gitlab::DataBuilder::Issuable#build' do
        expect(builder).to receive(:build).with(
          user: user,
          action: 'update',
          changes: hash_including(
            'labels' => [[labels[0].hook_attrs], [labels[1].hook_attrs]]
          ))

        issue.to_hook_data(user, old_associations: { labels: [labels[0]] }, action: 'update')
      end
    end

    context 'total_time_spent is updated' do
      before do
        issue.spend_time(duration: 2, user_id: user.id, spent_at: Time.current)
        issue.save!
        expect(Gitlab::DataBuilder::Issuable)
          .to receive(:new).with(issue).and_return(builder)
      end

      it 'delegates to Gitlab::DataBuilder::Issuable#build' do
        expect(builder).to receive(:build).with(
          user: user,
          action: 'update',
          changes: hash_including(
            'total_time_spent' => [1, 2]
          ))

        issue.to_hook_data(user, old_associations: { total_time_spent: 1 }, action: 'update')
      end
    end

    context 'issue is assigned' do
      let(:user2) { create(:user) }

      before do
        issue.assignees << user << user2
        expect(Gitlab::DataBuilder::Issuable)
          .to receive(:new).with(issue).and_return(builder)
      end

      it 'delegates to Gitlab::DataBuilder::Issuable#build', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/450843' do
        expect(builder).to receive(:build).with(
          user: user,
          action: 'update',
          changes: hash_including(
            'assignees' => [[user.hook_attrs], [user.hook_attrs, user2.hook_attrs]]
          ))

        issue.to_hook_data(user, old_associations: { assignees: [user] }, action: 'update')
      end
    end

    context 'merge_request is assigned' do
      let(:merge_request) { create(:merge_request) }
      let(:user2) { create(:user) }

      before do
        merge_request.update!(assignees: [user])
        merge_request.update!(assignees: [user, user2])
        expect(Gitlab::DataBuilder::Issuable)
          .to receive(:new).with(merge_request).and_return(builder)
      end

      it 'delegates to Gitlab::DataBuilder::Issuable#build' do
        expect(builder).to receive(:build).with(
          user: user,
          action: 'update',
          changes: hash_including(
            'assignees' => [[user.hook_attrs], [user.hook_attrs, user2.hook_attrs]]
          ))

        merge_request.to_hook_data(user, old_associations: { assignees: [user] }, action: 'update')
      end
    end

    context 'merge_request update reviewers' do
      let(:merge_request) { create(:merge_request) }
      let(:user2) { create(:user) }

      before do
        merge_request.update!(reviewers: [user])
        merge_request.update!(reviewers: [user, user2])
        expect(Gitlab::DataBuilder::Issuable)
          .to receive(:new).with(merge_request).and_return(builder)
      end

      it 'delegates to Gitlab::DataBuilder::Issuable#build' do
        expect(builder).to receive(:build).with(
          user: user,
          action: 'update',
          changes: hash_including(
            'reviewers' => [[user.hook_attrs], [user.hook_attrs, user2.hook_attrs]]
          ))
        merge_request.to_hook_data(user, old_associations: { reviewers: [user] }, action: 'update')
      end
    end

    context 'incident severity is updated' do
      let(:issue) { create(:incident) }

      before do
        issue.update!(issuable_severity_attributes: { severity: 'low' })
        expect(Gitlab::DataBuilder::Issuable)
          .to receive(:new).with(issue).and_return(builder)
      end

      it 'delegates to Gitlab::DataBuilder::Issuable#build' do
        expect(builder).to receive(:build).with(
          user: user,
          action: 'update',
          changes: hash_including(
            'severity' => %w[unknown low]
          ))

        issue.to_hook_data(user, old_associations: { severity: 'unknown' }, action: 'update')
      end
    end

    context 'escalation status is updated' do
      let(:issue) { create(:incident, :with_escalation_status) }
      let(:acknowledged) { IncidentManagement::IssuableEscalationStatus::STATUSES[:acknowledged] }

      before do
        issue.escalation_status.update!(status: acknowledged)

        expect(Gitlab::DataBuilder::Issuable).to receive(:new).with(issue).and_return(builder)
      end

      it 'delegates to Gitlab::DataBuilder::Issuable#build' do
        expect(builder).to receive(:build).with(
          user: user,
          action: 'update',
          changes: hash_including(
            'escalation_status' => %i[triggered acknowledged]
          ))

        issue.to_hook_data(user, old_associations: { escalation_status: :triggered }, action: 'update')
      end
    end

    context 'merge_request saved twice' do
      let(:merge_request) { create(:merge_request, :unchanged, target_branch: "initial-branch", title: "initial title") }

      before do
        merge_request.update!(target_branch: "some-other-branch")
        merge_request.update!(title: "temporary title")
        merge_request.update!(target_branch: "final-branch", title: "final title")

        expect(Gitlab::DataBuilder::Issuable).to receive(:new).with(merge_request).and_return(builder)
      end

      it 'includes the cumulative changes of both saves' do
        expect(builder).to receive(:build).with(
          user: user,
          action: 'update',
          changes: hash_including(
            'title' => ["initial title", "final title"],
            'target_branch' => %w[initial-branch final-branch]
          ))
        merge_request.to_hook_data(user, action: 'update')
      end
    end
  end

  describe "#importing_or_transitioning?" do
    let(:merge_request) { build(:merge_request, transitioning: transitioning, importing: importing) }

    where(:transitioning, :importing, :result) do
      true  | false | true
      false | true  | true
      true  | true  | true
      false | false | false
    end

    with_them do
      it { expect(merge_request.importing_or_transitioning?).to eq(result) }
    end
  end

  describe '#labels_array' do
    let(:project) { create(:project) }
    let(:bug) { create(:label, project: project, title: 'bug') }
    let(:issue) { create(:issue, project: project) }

    before do
      issue.labels << bug
    end

    it 'loads the association and returns it as an array' do
      expect(issue.reload.labels_array).to eq([bug])
    end
  end

  describe "#labels_hook_attrs" do
    let(:project) { create(:project) }
    let(:label) { create(:label) }
    let(:issue) { create(:labeled_issue, project: project, labels: [label]) }

    it "returns a list of label hook attributes" do
      expect(issue.labels_hook_attrs).to match_array([label.hook_attrs])
    end
  end

  describe '.labels_hash' do
    let(:feature_label) { create(:label, title: 'Feature') }
    let(:second_label) { create(:label, title: 'Second Label') }
    let!(:issues) { create_list(:labeled_issue, 3, labels: [feature_label, second_label]) }
    let(:issue_id) { issues.first.id }

    it 'maps issue ids to labels titles' do
      expect(Issue.labels_hash[issue_id]).to include('Feature')
    end

    it 'works on relations filtered by multiple labels' do
      relation = Issue.with_label(['Feature', 'Second Label'])

      expect(relation.labels_hash[issue_id]).to include('Feature', 'Second Label')
    end

    # This tests the workaround for the lack of a NOT NULL constraint in
    # label_links.label_id:
    # https://gitlab.com/gitlab-org/gitlab/issues/197307
    context 'with a NULL label ID in the link' do
      let(:issue) { create(:labeled_issue, labels: [feature_label, second_label]) }

      before do
        label_link = issue.label_links.find_by(label_id: second_label.id)
        label_link.label_id = nil
        label_link.save!(validate: false)
      end

      it 'filters out bad labels' do
        expect(Issue.where(id: issue.id).labels_hash[issue.id]).to match_array(['Feature'])
      end
    end
  end

  describe '#user_notes_count' do
    let(:project) { create(:project) }
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
    let(:project) { create(:project) }

    def create_issue(milestone, labels)
      create(:labeled_issue, milestone: milestone, labels: labels, project: project)
    end

    it 'sorts issues in order of milestone due date, then label priority' do
      first_priority = create(:label, project: project, priority: 1)
      second_priority = create(:label, project: project, priority: 2)
      no_priority = create(:label, project: project)

      first_milestone = create(:milestone, project: project, due_date: Time.current)
      second_milestone = create(:milestone, project: project, due_date: Time.current + 1.month)
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
    let(:project) { create(:project, :public) }
    let(:bug) { create(:label, project: project, title: 'bug') }
    let(:feature) { create(:label, project: project, title: 'feature') }
    let(:enhancement) { create(:label, project: project, title: 'enhancement') }
    let(:issue1) { create(:issue, title: "Bugfix1", project: project) }
    let(:issue2) { create(:issue, title: "Bugfix2", project: project) }
    let(:issue3) { create(:issue, title: "Feature1", project: project) }

    before do
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
      issue.spend_time(duration: seconds, user_id: user.id)
      issue.save!
    end

    context 'adding time' do
      it 'updates the total time spent' do
        spend_time(1800)

        expect(issue.total_time_spent).to eq(1800)
      end

      it 'stores the time change' do
        spend_time(1800)

        expect(issue.time_change).to eq(1800)
      end

      it 'updates issues updated_at' do
        issue

        travel_to(2.minutes.from_now) do
          expect { spend_time(1800) }.to change { issue.updated_at }
        end
      end
    end

    context 'subtracting time' do
      before do
        spend_time(1800)
      end

      it 'updates the total time spent' do
        spend_time(-900)

        expect(issue.total_time_spent).to eq(900)
      end

      it 'stores negative time change' do
        spend_time(-900)

        expect(issue.time_change).to eq(-900)
      end

      context 'when time to subtract exceeds the total time spent' do
        it 'raise a validation error' do
          travel_to(1.minute.from_now) do
            expect do
              expect do
                spend_time(-3600)
              end.to raise_error(ActiveRecord::RecordInvalid)
            end.not_to change { issue.updated_at }
          end
        end
      end
    end
  end

  describe '#first_contribution?', feature_category: :code_review_workflow do
    let(:group) { create(:group) }
    let(:project) { create(:project, namespace: group) }
    let(:other_project) { create(:project) }
    let(:guest) { create(:user) }

    let(:contributor) { create(:user) }
    let(:first_time_contributor) { create(:user) }

    before do
      project.add_guest(guest)
      project.add_guest(contributor)
      project.add_guest(first_time_contributor)
    end

    let(:merged_mr) { create(:merge_request, :merged, author: contributor, target_project: project, source_project: project) }
    let(:open_mr) { create(:merge_request, author: first_time_contributor, target_project: project, source_project: project) }
    let(:merged_mr_other_project) { create(:merge_request, :merged, author: first_time_contributor, target_project: other_project, source_project: other_project) }

    context "for merge requests" do
      it "is true when you don't have any merged MR" do
        expect(open_mr).to be_first_contribution
        expect(merged_mr).not_to be_first_contribution
      end

      it "handles multiple projects separately" do
        expect(open_mr).to be_first_contribution
        expect(merged_mr_other_project).not_to be_first_contribution
      end
    end

    context "for issues" do
      let(:contributor_issue) { create(:issue, author: contributor, project: project) }
      let(:first_time_contributor_issue) { create(:issue, author: first_time_contributor, project: project) }

      it "is false even without merged MR" do
        expect(merged_mr).to be_present
        expect(first_time_contributor_issue).not_to be_first_contribution
        expect(contributor_issue).not_to be_first_contribution
      end
    end
  end

  describe '#matches_cross_reference_regex?' do
    context "issue description with long path string" do
      let(:mentionable) { build(:issue, description: "/a" * 50000) }

      it_behaves_like 'matches_cross_reference_regex? fails fast'
    end

    context "note with long path string" do
      let(:mentionable) { build(:note, note: "/a" * 50000) }

      it_behaves_like 'matches_cross_reference_regex? fails fast'
    end

    context "note with long path string" do
      let(:project) { create(:project, :public, :repository) }
      let(:mentionable) { project.commit }

      before do
        expect(mentionable.raw).to receive(:message).and_return("/a" * 50000)
      end

      it_behaves_like 'matches_cross_reference_regex? fails fast'
    end
  end

  describe '#supports_time_tracking?' do
    where(:issuable_type, :supports_time_tracking) do
      :issue         | true
      :incident      | true
      :merge_request | true
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type) }

      subject { issuable.supports_time_tracking? }

      it { is_expected.to eq(supports_time_tracking) }
    end
  end

  describe '#supports_severity?' do
    where(:issuable_type, :supports_severity) do
      :issue         | false
      :incident      | true
      :merge_request | false
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type) }

      subject { issuable.supports_severity? }

      it { is_expected.to eq(supports_severity) }
    end
  end

  describe '#supports_escalation?' do
    where(:issuable_type, :supports_escalation) do
      :issue         | false
      :incident      | true
      :merge_request | false
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type) }

      subject { issuable.supports_escalation? }

      it { is_expected.to eq(supports_escalation) }
    end
  end

  describe '#incident_type_issue?' do
    where(:issuable_type, :incident) do
      :issue         | false
      :incident      | true
      :merge_request | false
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type) }

      subject { issuable.incident_type_issue? }

      it { is_expected.to eq(incident) }
    end
  end

  describe '#supports_issue_type?' do
    where(:issuable_type, :supports_issue_type) do
      :issue         | true
      :merge_request | false
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type) }

      subject { issuable.supports_issue_type? }

      it { is_expected.to eq(supports_issue_type) }
    end
  end

  describe '#supports_confidentiality?' do
    where(:issuable_type, :supports_confidentiality) do
      :issue         | true
      :incident      | true
      :merge_request | false
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type) }

      subject { issuable.supports_confidentiality? }

      it { is_expected.to eq(supports_confidentiality) }
    end
  end

  describe '#supports_lock_on_merge?' do
    where(:issuable_type, :supports_lock_on_merge) do
      :issue         | false
      :merge_request | false
      :incident      | false
    end

    with_them do
      let(:issuable) { build_stubbed(issuable_type) }

      subject { issuable.supports_lock_on_merge? }

      it { is_expected.to eq(supports_lock_on_merge) }
    end
  end

  describe '#severity' do
    subject { issuable.severity }

    context 'when issuable is not an incident' do
      where(:issuable_type, :severity) do
        :issue         | 'unknown'
        :merge_request | 'unknown'
      end

      with_them do
        let(:issuable) { build_stubbed(issuable_type) }

        it { is_expected.to eq(severity) }
      end
    end

    context 'when issuable type is an incident' do
      let!(:issuable) { build_stubbed(:incident) }

      context 'when incident does not have issuable_severity' do
        it 'returns default serverity' do
          is_expected.to eq(IssuableSeverity::DEFAULT)
        end
      end

      context 'when incident has issuable_severity' do
        let!(:issuable_severity) { build_stubbed(:issuable_severity, issue: issuable, severity: 'critical') }

        it 'returns issuable serverity' do
          is_expected.to eq('critical')
        end
      end
    end
  end

  context 'with exportable associations' do
    let_it_be(:project) { create(:project, group: create(:group, :private)) }

    context 'for issues' do
      let_it_be_with_reload(:resource) { create(:issue, project: project) }

      it_behaves_like 'an exportable'
    end

    context 'for merge requests' do
      let_it_be_with_reload(:resource) do
        create(:merge_request, source_project: project, project: project)
      end

      it_behaves_like 'an exportable'
    end
  end
end
