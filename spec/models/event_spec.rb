# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Event, feature_category: :user_profile do
  let_it_be_with_reload(:project) { create(:project) }

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:target) }
  end

  describe "Respond to" do
    it { is_expected.to respond_to(:author_name) }
    it { is_expected.to respond_to(:author_email) }
    it { is_expected.to respond_to(:issue_title) }
    it { is_expected.to respond_to(:merge_request_title) }
    it { is_expected.to respond_to(:design_title) }
  end

  describe 'Callbacks' do
    describe 'after_create :reset_project_activity' do
      it 'calls the reset_project_activity method' do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:reset_project_activity)
        end

        create_push_event(project, project.first_owner)
      end
    end

    describe 'after_create :set_last_repository_updated_at' do
      context 'with a push event' do
        it 'updates the project last_repository_updated_at' do
          project.update!(last_repository_updated_at: 1.year.ago)

          event = create_push_event(project, project.first_owner)

          project.reload

          expect(project.last_repository_updated_at).to be_like_time(event.created_at)
        end

        it 'calls the reset_project_activity method' do
          expect_next_instance_of(described_class) do |instance|
            expect(instance).to receive(:reset_project_activity)
          end

          create_push_event(project, project.first_owner)
        end
      end

      context 'without a push event' do
        it 'does not update the project last_repository_updated_at' do
          project.update!(last_repository_updated_at: 1.year.ago)

          create(:closed_issue_event, project: project, author: project.first_owner)

          project.reload

          expect(project.last_repository_updated_at).to be_within(1.minute).of(1.year.ago)
        end
      end
    end

    describe '#set_last_repository_updated_at' do
      it 'only updates once every Event::REPOSITORY_UPDATED_AT_INTERVAL minutes' do
        last_known_timestamp = (Event::REPOSITORY_UPDATED_AT_INTERVAL - 1.minute).ago
        project.update!(last_repository_updated_at: last_known_timestamp)
        project.reload # a reload removes fractions of seconds

        expect do
          create_push_event(project, project.first_owner)
          project.reload
        end.not_to change { project.last_repository_updated_at }
      end
    end
  end

  describe 'validations' do
    describe 'action' do
      context 'for a design' do
        let_it_be(:author) { create(:user) }

        where(:action, :valid) do
          valid = described_class::DESIGN_ACTIONS.map(&:to_s).to_set

          described_class.actions.keys.map do |action|
            [action, valid.include?(action)]
          end
        end

        with_them do
          let(:event) { build(:design_event, author: author, action: action) }

          specify { expect(event.valid?).to eq(valid) }
        end
      end
    end
  end

  describe 'scopes' do
    describe '.for_issue' do
      let(:issue_event) { create(:event, :for_issue, project: project) }
      let(:work_item_event) { create(:event, :for_work_item, project: project) }

      before do
        create(:event, :for_design, project: project)
      end

      it 'returns events for Issue and WorkItem target_type' do
        expect(described_class.for_issue).to contain_exactly(issue_event, work_item_event)
      end
    end

    describe '.for_merge_request' do
      let(:mr_event) { create(:event, :for_merge_request, project: project) }

      before do
        create(:event, :for_issue, project: project)
      end

      it 'returns events for MergeRequest target_type' do
        expect(described_class.for_merge_request).to contain_exactly(mr_event)
      end
    end

    describe '.created_at' do
      it 'can find the right event' do
        time = 1.day.ago
        event = create(:event, created_at: time, project: project)
        false_positive = create(:event, created_at: 2.days.ago)

        found = described_class.created_at(time)

        expect(found).to include(event)
        expect(found).not_to include(false_positive)
      end
    end

    describe '.created_between' do
      it 'returns events created between given timestamps' do
        start_time = 2.days.ago
        end_time = Date.today

        create(:event, created_at: 3.days.ago)
        e1 = create(:event, created_at: 2.days.ago)
        e2 = create(:event, created_at: 1.day.ago)

        found = described_class.created_between(start_time, end_time)

        expect(found).to contain_exactly(e1, e2)
      end
    end

    describe '.for_fingerprint' do
      let_it_be(:with_fingerprint) { create(:event, fingerprint: 'aaa', project: project) }

      before_all do
        create(:event, project: project)
        create(:event, fingerprint: 'bbb', project: project)
      end

      it 'returns none if there is no fingerprint' do
        expect(described_class.for_fingerprint(nil)).to be_empty
        expect(described_class.for_fingerprint('')).to be_empty
      end

      it 'returns none if there is no match' do
        expect(described_class.for_fingerprint('not-found')).to be_empty
      end

      it 'can find a given event' do
        expect(described_class.for_fingerprint(with_fingerprint.fingerprint))
          .to contain_exactly(with_fingerprint)
      end
    end

    describe '.contributions' do
      let!(:merge_request_events) do
        %i[created closed merged approved].map do |action|
          create(:event, :for_merge_request, action: action, project: project)
        end
      end

      let!(:work_item_event) { create(:event, :created, :for_work_item, project: project) }
      let!(:issue_events) do
        %i[created closed].map { |action| create(:event, :for_issue, action: action, project: project) }
      end

      let!(:push_event) { create_push_event(project, project.owner) }
      let!(:comment_event) { create(:event, :commented, project: project) }

      before do
        create(:design_event, project: project) # should not be in scope
      end

      it 'returns events for MergeRequest, Issue, WorkItem and push, comment events' do
        expect(described_class.contributions).to contain_exactly(
          *merge_request_events, *issue_events, work_item_event,
          push_event, comment_event
        )
      end
    end
  end

  describe '#fingerprint' do
    it 'is unique scoped to target' do
      issue = create(:issue, project: project)
      mr = create(:merge_request, source_project: project)

      expect { create_list(:event, 2, target: issue, fingerprint: '1234', project: project) }
        .to raise_error(include('fingerprint'))

      expect do
        create(:event, target: mr, fingerprint: 'abcd', project: project)
        create(:event, target: issue, fingerprint: 'abcd', project: project)
        create(:event, target: issue, fingerprint: 'efgh', project: project)
      end.not_to raise_error
    end
  end

  describe "Push event" do
    let(:private_project) { create(:project, :private) }
    let(:user) { private_project.first_owner }
    let(:event) { create_push_event(private_project, user) }

    it do
      expect(event.push_action?).to be_truthy
      expect(event.visible_to_user?(user)).to be_truthy
      expect(event.visible_to_user?(nil)).to be_falsey
      expect(event.tag?).to be_falsey
      expect(event.branch_name).to eq("master")
      expect(event.author).to eq(user)
    end
  end

  describe '#target_title' do
    let(:author) { project.first_owner }
    let(:target) { nil }

    let(:event) do
      described_class.new(project: project, target: target, author_id: author.id)
    end

    context 'for an issue' do
      let(:title) { generate(:title) }
      let(:issue) { create(:issue, title: title, project: project) }
      let(:target) { issue }

      it 'delegates to issue title' do
        expect(event.target_title).to eq(title)
      end
    end

    context 'for a wiki page' do
      let(:title) { generate(:wiki_page_title) }
      let(:wiki_page) { create(:wiki_page, title: title, project: project) }
      let(:event) { create(:wiki_page_event, project: project, wiki_page: wiki_page) }

      it 'delegates to wiki page title' do
        expect(event.target_title).to eq(wiki_page.title)
      end
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
    let_it_be(:non_member) { create(:user) }
    let_it_be(:member) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:author) { create(:author) }
    let_it_be(:assignee) { create(:user) }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:private_project) { create(:project, :private) }

    let(:project) { public_project }
    let(:issue) { create(:issue, project: project, author: author, assignees: [assignee]) }
    let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignees: [assignee]) }
    let(:work_item) { create(:work_item, project: project, author: author) }
    let(:confidential_work_item) { create(:work_item, :confidential, project: project, author: author) }
    let(:project_snippet) { create(:project_snippet, :public, project: project, author: author) }
    let(:personal_snippet) { create(:personal_snippet, :public, author: author) }
    let(:design) { create(:design, issue: issue, project: project) }
    let(:note_on_commit) { create(:note_on_commit, project: project) }
    let(:note_on_issue) { create(:note_on_issue, noteable: issue, project: project) }
    let(:confidential_note) { create(:note, noteable: issue, project: project, confidential: true) }
    let(:note_on_confidential_issue) { create(:note_on_issue, noteable: confidential_issue, project: project) }
    let(:note_on_project_snippet) { create(:note_on_project_snippet, author: author, noteable: project_snippet, project: project) }
    let(:note_on_personal_snippet) { create(:note_on_personal_snippet, author: author, noteable: personal_snippet, project: nil) }
    let(:note_on_design) { create(:note_on_design, author: author, noteable: design, project: project) }
    let(:note_on_wiki_page) { create(:note_on_wiki_page, author: author, project: project) }
    let(:milestone_on_project) { create(:milestone, project: project) }
    let(:event) do
      described_class.new(project: project, target: target, author_id: author.id)
    end

    before do
      project.add_developer(member)
      project.add_guest(guest)
    end

    def visible_to_all
      {
        logged_out: true,
        non_member: true,
        guest: true,
        member: true,
        admin: true
      }
    end

    def visible_to_none
      visible_to_all.transform_values { |_| false }
    end

    def visible_to_none_except(*roles)
      visible_to_none.merge(roles.index_with { true })
    end

    def visible_to_all_except(*roles)
      visible_to_all.merge(roles.index_with { false })
    end

    shared_examples 'visibility examples' do
      it 'has the correct visibility' do
        expect({
          logged_out: event.visible_to_user?(nil),
          non_member: event.visible_to_user?(non_member),
          guest: event.visible_to_user?(guest),
          member: event.visible_to_user?(member),
          admin: event.visible_to_user?(admin)
        }).to match(visibility)
      end
    end

    shared_examples 'visible to assignee' do |visible|
      it { expect(event.visible_to_user?(assignee)).to eq(visible) }
    end

    shared_examples 'visible to author' do |visible|
      it { expect(event.visible_to_user?(author)).to eq(visible) }
    end

    shared_examples 'visible to assignee and author' do |visible|
      include_examples 'visible to assignee', visible
      include_examples 'visible to author', visible
    end

    context 'commit note event' do
      let(:project) { create(:project, :public, :repository) }
      let(:target) { note_on_commit }

      include_examples 'visibility examples' do
        let(:visibility) { visible_to_all }
      end

      context 'private project' do
        let(:project) { create(:project, :private, :repository) }

        context 'when admin mode enabled', :enable_admin_mode do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:member, :admin) }
          end
        end

        context 'when admin mode disabled' do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:member) }
          end
        end
      end
    end

    context 'issue event' do
      context 'for non confidential issues' do
        let(:target) { issue }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_all }
        end

        include_examples 'visible to assignee and author', true
      end

      context 'for confidential issues' do
        let(:target) { confidential_issue }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_none_except(:member, :admin) }
        end

        include_examples 'visible to assignee and author', true
      end
    end

    context 'work item event' do
      context 'for non confidential work item' do
        let(:target) { work_item }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_all }
        end

        include_examples 'visible to assignee and author', true
      end

      context 'for confidential work item' do
        let(:target) { confidential_work_item }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_none_except(:member, :admin) }
        end

        include_examples 'visible to author', true
      end
    end

    context 'issue note event' do
      context 'on non confidential issues' do
        let(:target) { note_on_issue }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_all }
        end

        include_examples 'visible to assignee and author', true
      end

      context 'on confidential issues' do
        let(:target) { note_on_confidential_issue }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_none_except(:member, :admin) }
        end

        include_examples 'visible to assignee and author', true
      end

      context 'confidential note' do
        let(:target) { confidential_note }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_none_except(:member) }
        end
      end

      context 'private project' do
        let(:project) { private_project }
        let(:target) { note_on_issue }

        context 'when admin mode enabled', :enable_admin_mode do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:guest, :member, :admin) }
          end
        end

        context 'when admin mode disabled' do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:guest, :member) }
          end
        end

        include_examples 'visible to assignee and author', false
      end
    end

    context 'merge request diff note event' do
      let(:merge_request) { create(:merge_request, source_project: project, author: author, assignees: [assignee]) }
      let(:note_on_merge_request) { create(:legacy_diff_note_on_merge_request, noteable: merge_request, project: project) }
      let(:target) { note_on_merge_request }

      context 'public project' do
        let(:project) { public_project }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_all }
        end

        include_examples 'visible to assignee', true
      end

      context 'private project' do
        let(:project) { private_project }

        context 'when admin mode enabled', :enable_admin_mode do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:member, :admin) }
          end
        end

        context 'when admin mode disabled' do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:member) }
          end
        end

        include_examples 'visible to assignee', false
      end
    end

    context 'milestone event' do
      let(:target) { milestone_on_project }

      include_examples 'visibility examples' do
        let(:visibility) { visible_to_all }
      end

      context 'on public project with private issue tracker and merge requests' do
        let(:project) { create(:project, :public, :issues_private, :merge_requests_private) }

        context 'when admin mode enabled', :enable_admin_mode do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_all_except(:logged_out, :non_member) }
          end
        end

        context 'when admin mode disabled' do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_all_except(:logged_out, :non_member, :admin) }
          end
        end
      end

      context 'on private project' do
        let(:project) { create(:project, :private) }

        context 'when admin mode enabled', :enable_admin_mode do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_all_except(:logged_out, :non_member) }
          end
        end

        context 'when admin mode disabled' do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_all_except(:logged_out, :non_member, :admin) }
          end
        end
      end
    end

    context 'wiki-page event', :aggregate_failures do
      let(:event) { create(:wiki_page_event, project: project) }

      context 'on private project', :aggregate_failures do
        let(:project) { create(:project, :wiki_repo) }

        context 'when admin mode enabled', :enable_admin_mode do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_all_except(:logged_out, :non_member) }
          end
        end

        context 'when admin mode disabled' do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_all_except(:logged_out, :non_member, :admin) }
          end
        end
      end

      context 'wiki-page event on public project', :aggregate_failures do
        let(:project) { create(:project, :public, :wiki_repo) }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_all }
        end
      end
    end

    context 'wiki page note event', :aggregate_failures do
      let(:event) { create(:event, :for_wiki_page_note, project: project) }

      context 'on private project', :aggregate_failures do
        let(:project) { create(:project, :wiki_repo) }

        context 'when admin mode enabled', :enable_admin_mode do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_all_except(:logged_out, :non_member) }
          end
        end

        context 'when admin mode disabled' do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_all_except(:logged_out, :non_member, :admin) }
          end
        end
      end

      context 'wiki-page event on public project', :aggregate_failures do
        let(:project) { create(:project, :public, :wiki_repo) }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_all }
        end
      end
    end

    context 'project snippet note event' do
      let(:target) { note_on_project_snippet }

      include_examples 'visibility examples' do
        let(:visibility) { visible_to_all }
      end

      context 'on public project with private snippets' do
        let(:project) { create(:project, :public, :snippets_private) }

        context 'when admin mode enabled', :enable_admin_mode do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:guest, :member, :admin) }
          end
        end

        context 'when admin mode disabled' do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:guest, :member) }
          end
        end

        # Normally, we'd expect the author of a comment to be able to view it.
        # However, this doesn't seem to be the case for comments on snippets.

        include_examples 'visible to author', false
      end

      context 'on private project' do
        let(:project) { create(:project, :private) }

        context 'when admin mode enabled', :enable_admin_mode do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:guest, :member, :admin) }
          end
        end

        context 'when admin mode disabled' do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:guest, :member) }
          end
        end

        # Normally, we'd expect the author of a comment to be able to view it.
        # However, this doesn't seem to be the case for comments on snippets.

        include_examples 'visible to author', false
      end
    end

    context 'personal snippet note event' do
      let(:target) { note_on_personal_snippet }

      include_examples 'visibility examples' do
        let(:visibility) { visible_to_all }
      end

      include_examples 'visible to author', true

      context 'on internal snippet' do
        let(:personal_snippet) { create(:personal_snippet, :internal, author: author) }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_all_except(:logged_out) }
        end
      end

      context 'on private snippet' do
        let(:personal_snippet) { create(:personal_snippet, :private, author: author) }

        context 'when admin mode enabled', :enable_admin_mode do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none_except(:admin) }
          end
        end

        context 'when admin mode disabled' do
          include_examples 'visibility examples' do
            let(:visibility) { visible_to_none }
          end
        end

        include_examples 'visible to author', true
      end
    end

    context 'design note event' do
      include DesignManagementTestHelpers

      let(:target) { note_on_design }

      before do
        enable_design_management
      end

      include_examples 'visibility examples' do
        let(:visibility) { visible_to_all }
      end

      include_examples 'visible to assignee and author', true

      context 'the event refers to a design on a confidential issue' do
        let(:design) { create(:design, issue: confidential_issue, project: project) }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_none_except(:member, :admin) }
        end

        include_examples 'visible to assignee and author', true
      end
    end

    context 'design event' do
      include DesignManagementTestHelpers

      let(:target) { design }

      before do
        enable_design_management
      end

      include_examples 'visibility examples' do
        let(:visibility) { visible_to_all }
      end

      include_examples 'visible to assignee and author', true

      context 'the event refers to a design on a confidential issue' do
        let(:design) { create(:design, issue: confidential_issue, project: project) }

        include_examples 'visibility examples' do
          let(:visibility) { visible_to_none_except(:member, :admin) }
        end

        include_examples 'visible to assignee and author', true
      end
    end
  end

  describe 'wiki_page predicate scopes' do
    let_it_be(:events) do
      [
        create(:push_event),
        create(:closed_issue_event),
        create(:wiki_page_event),
        create(:closed_issue_event),
        create(:event, :created),
        create(:design_event, :destroyed),
        create(:wiki_page_event),
        create(:design_event)
      ]
    end

    describe '.for_design' do
      it 'only includes design events' do
        design_events = events.select(&:design?)

        expect(described_class.for_design)
          .to be_present
          .and match_array(design_events)
      end
    end

    describe '.for_wiki_page' do
      it 'only contains the wiki page events' do
        wiki_events = events.select(&:wiki_page?)

        expect(events).not_to match_array(wiki_events)
        expect(described_class.for_wiki_page).to match_array(wiki_events)
      end
    end

    describe '.for_wiki_meta' do
      it 'finds events for a given wiki page metadata object' do
        event = events.find(&:wiki_page?)

        expect(described_class.for_wiki_meta(event.target)).to contain_exactly(event)
      end
    end
  end

  describe 'categorization' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:all_valid_events) do
      # mapping from factory name to whether we need to supply the project
      valid_target_factories = {
        issue: true,
        note_on_issue: true,
        user: false,
        merge_request: true,
        note_on_merge_request: true,
        project_snippet: true,
        personal_snippet: false,
        note_on_project_snippet: true,
        note_on_personal_snippet: false,
        wiki_page_meta: true,
        milestone: true,
        project: false,
        design: true,
        note_on_design: true,
        note_on_commit: true
      }
      valid_target_factories.to_h do |kind, needs_project|
        extra_data = if kind == :merge_request
                       { source_project: project }
                     elsif needs_project
                       { project: project }
                     else
                       {}
                     end

        target = kind == :project ? nil : build(kind, **extra_data)

        [kind, build(:event, :created, author: project.first_owner, project: project, target: target)]
      end
    end

    it 'passes a sanity check', :aggregate_failures do
      expect(all_valid_events.values).to all(be_valid)
    end

    describe '#wiki_page and #wiki_page?' do
      context 'for a wiki page event' do
        let(:wiki_page) { create(:wiki_page, project: project) }

        subject(:event) { create(:wiki_page_event, project: project, wiki_page: wiki_page) }

        it { is_expected.to have_attributes(wiki_page?: be_truthy, wiki_page: wiki_page) }

        context 'title is empty' do
          before do
            expect(event.target).to receive(:canonical_slug).and_return('')
          end

          it { is_expected.to have_attributes(wiki_page?: be_truthy, wiki_page: nil) }
        end
      end

      context 'for any other event' do
        it 'has no wiki_page and is not a wiki_page', :aggregate_failures do
          all_valid_events.each do |k, event|
            next if k == :wiki_page_meta

            expect(event).to have_attributes(wiki_page: be_nil, wiki_page?: be_falsy)
          end
        end
      end
    end

    describe '#design and #design?' do
      context 'for a design event' do
        let(:design) { build(:design, project: project) }

        subject(:event) { build(:design_event, target: design, project: project) }

        it { is_expected.to have_attributes(design?: be_truthy, design: design) }
      end

      context 'for any other event' do
        it 'has no design and is not a design', :aggregate_failures do
          all_valid_events.each do |k, event|
            next if k == :design

            expect(event).to have_attributes(design: be_nil, design?: be_falsy)
          end
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

  describe '#update_project_activity' do
    let(:project) { create(:project) }

    context 'when last_activity_at has to be updated, but last_repository_updated_at not' do
      before do
        project.update!(
          last_activity_at: described_class::RESET_PROJECT_ACTIVITY_INTERVAL.ago - 5.minutes,
          last_repository_updated_at: Time.current
        )
        project.reload

        ::Gitlab::Redis::SharedState.with do |redis|
          redis.hset('inactive_projects_deletion_warning_email_notified', "project:#{project.id}", Date.current.to_s)
        end
      end

      it 'updates the column' do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis).to receive(:hdel).with(
            'inactive_projects_deletion_warning_email_notified',
            "project:#{project.id}"
          )
        end

        last_repository_updated_at = project.last_repository_updated_at

        event = create_push_event(project, project.first_owner)

        project.reload
        event.reload

        expect(project.last_repository_updated_at).to eq(last_repository_updated_at)
        expect(project.last_activity_at).to eq(event.created_at)
        expect(project.updated_at).to eq(event.created_at)
      end
    end

    context 'when last_activity_at does not have to be updated, but last_repository_updated_at has' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis).not_to receive(:hdel)
        end

        project.update!(
          last_activity_at: Time.current,
          last_repository_updated_at: described_class::REPOSITORY_UPDATED_AT_INTERVAL.ago - 5.minutes
        )
        project.reload
      end

      context 'with push event' do
        it 'updates the column' do
          last_activity_at = project.last_activity_at

          event = create_push_event(project, project.first_owner)

          project.reload
          event.reload

          expect(project.last_activity_at).to eq(last_activity_at)
          expect(project.last_repository_updated_at).to eq(event.created_at)
          expect(project.updated_at).to eq(event.created_at)
        end
      end

      context 'without push event' do
        it 'does not update the columns' do
          updated_at = project.updated_at
          last_activity_at = project.last_activity_at
          last_repository_updated_at = project.last_repository_updated_at

          create(:closed_issue_event, project: project, author: project.first_owner)

          project.reload

          expect(project.last_activity_at).to eq(last_activity_at)
          expect(project.last_repository_updated_at).to eq(last_repository_updated_at)
          expect(project.updated_at).to eq(updated_at)
        end
      end
    end

    context 'when both last_activity_at and last_repository_updated_at have to be updated' do
      before do
        project.update!(
          last_activity_at: described_class::RESET_PROJECT_ACTIVITY_INTERVAL.ago - 5.minutes,
          last_repository_updated_at: described_class::REPOSITORY_UPDATED_AT_INTERVAL.ago - 5.minutes
        )
        project.reload

        ::Gitlab::Redis::SharedState.with do |redis|
          redis.hset('inactive_projects_deletion_warning_email_notified', "project:#{project.id}", Date.current.to_s)
        end
      end

      it 'updates the columns' do
        event = create_push_event(project, project.first_owner)

        project.reload
        event.reload

        expect(project.last_activity_at).to eq(event.created_at)
        expect(project.last_repository_updated_at).to eq(event.created_at)
        expect(project.updated_at).to eq(event.created_at)
      end
    end

    context 'when none of last_activity_at and last_repository_updated_at have to be updated' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis).not_to receive(:hdel)
        end

        project.update!(
          last_activity_at: Time.current,
          last_repository_updated_at: Time.current
        )
        project.reload
      end

      context 'with push event' do
        it 'does not update the columns' do
          updated_at = project.updated_at
          last_activity_at = project.last_activity_at
          last_repository_updated_at = project.last_repository_updated_at

          create_push_event(project, project.first_owner)

          project.reload

          expect(project.last_activity_at).to eq(last_activity_at)
          expect(project.last_repository_updated_at).to eq(last_repository_updated_at)
          expect(project.updated_at).to eq(updated_at)
        end
      end

      context 'without push event' do
        it 'does not update the columns' do
          updated_at = project.updated_at
          last_activity_at = project.last_activity_at
          last_repository_updated_at = project.last_repository_updated_at

          create(:closed_issue_event, project: project, author: project.first_owner)

          project.reload

          expect(project.last_activity_at).to eq(last_activity_at)
          expect(project.last_repository_updated_at).to eq(last_repository_updated_at)
          expect(project.updated_at).to eq(updated_at)
        end
      end
    end
  end

  describe '#reset_project_activity' do
    let(:project) { create(:project) }

    context 'when a project was updated less than 1 hour ago' do
      it 'does not update the project' do
        project.update!(last_activity_at: Time.current)

        expect(project).not_to receive(:update_column)
          .with(:last_activity_at, a_kind_of(Time))

        create_push_event(project, project.first_owner)
      end
    end

    context 'when a project was updated more than 1 hour ago', :clean_gitlab_redis_shared_state do
      before do
        ::Gitlab::Redis::SharedState.with do |redis|
          redis.hset('inactive_projects_deletion_warning_email_notified', "project:#{project.id}", Date.current.to_s)
        end
      end

      it 'updates the project' do
        project.update!(last_activity_at: 1.year.ago)

        event = create_push_event(project, project.first_owner)

        project.reload

        expect(project.last_activity_at).to be_like_time(event.created_at)
      end

      it "deletes the redis key for if the project was inactive" do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis).to receive(:hdel).with(
            'inactive_projects_deletion_warning_email_notified',
            "project:#{project.id}"
          )
        end

        project.touch(:last_activity_at, time: 1.year.ago)

        create_push_event(project, project.first_owner)
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

  context 'with snippet note' do
    let_it_be(:user) { create(:user) }
    let_it_be(:note_on_project_snippet) { create(:note_on_project_snippet, author: user) }
    let_it_be(:note_on_personal_snippet) { create(:note_on_personal_snippet, author: user) }
    let_it_be(:other_note) { create(:note_on_issue, author: user) }
    let_it_be(:personal_snippet_event) { create(:event, :commented, project: nil, target: note_on_personal_snippet, author: user) }
    let_it_be(:project_snippet_event) { create(:event, :commented, project: note_on_project_snippet.project, target: note_on_project_snippet, author: user) }
    let_it_be(:other_event) { create(:event, :commented, project: other_note.project, target: other_note, author: user) }

    describe '#snippet_note?' do
      it 'returns true for a project snippet event' do
        expect(project_snippet_event.snippet_note?).to be true
      end

      it 'returns true for a personal snippet event' do
        expect(personal_snippet_event.snippet_note?).to be true
      end

      it 'returns false for a other kinds of event' do
        expect(other_event.snippet_note?).to be false
      end
    end

    describe '#personal_snippet_note?' do
      it 'returns false for a project snippet event' do
        expect(project_snippet_event.personal_snippet_note?).to be false
      end

      it 'returns true for a personal snippet event' do
        expect(personal_snippet_event.personal_snippet_note?).to be true
      end

      it 'returns false for a other kinds of event' do
        expect(other_event.personal_snippet_note?).to be false
      end
    end

    describe '#project_snippet_note?' do
      it 'returns true for a project snippet event' do
        expect(project_snippet_event.project_snippet_note?).to be true
      end

      it 'returns false for a personal snippet event' do
        expect(personal_snippet_event.project_snippet_note?).to be false
      end

      it 'returns false for a other kinds of event' do
        expect(other_event.project_snippet_note?).to be false
      end
    end
  end

  describe '#action_name' do
    it 'handles all valid design events' do
      created, updated, destroyed = %i[created updated destroyed].map do |trait|
        build(:design_event, trait).action_name
      end

      expect(created).to eq('added')
      expect(updated).to eq('updated')
      expect(destroyed).to eq('removed')
    end

    it 'handles correct push_action' do
      project = create(:project)
      user = create(:user)
      project.add_developer(user)
      push_event = create_push_event(project, user)

      expect(push_event.push_action?).to be true
      expect(push_event.action_name).to eq('pushed to')
    end

    context 'handles correct base actions' do
      using RSpec::Parameterized::TableSyntax

      where(:trait, :action_name) do
        :created   | 'created'
        :updated   | 'opened'
        :closed    | 'closed'
        :reopened  | 'opened'
        :commented | 'commented on'
        :merged    | 'accepted'
        :joined    | 'joined'
        :left      | 'left'
        :destroyed | 'destroyed'
        :expired   | 'removed due to membership expiration from'
        :approved  | 'approved'
      end

      with_them do
        it 'with correct name and method' do
          event = build(:event, trait)

          expect(event.action_name).to eq(action_name)
        end
      end
    end

    context 'for created_project_action?' do
      it 'returns created for created event' do
        action = build(:project_created_event)

        expect(action.action_name).to eq('created')
      end

      it 'returns imported for imported event' do
        action = build(:project_imported_event)

        expect(action.action_name).to eq('imported')
      end
    end
  end

  describe '#has_no_project_and_group' do
    context 'with project event' do
      it 'returns false when the event has project' do
        event = build(:event, project: create(:project))

        expect(event.has_no_project_and_group?).to be false
      end

      it 'returns true when the event has no project' do
        event = build(:event, project: nil)

        expect(event.has_no_project_and_group?).to be true
      end
    end

    context 'with group event' do
      it 'returns false when the event has group' do
        event = build(:event, group: create(:group))

        expect(event.has_no_project_and_group?).to be false
      end

      it 'returns true when the event has no group' do
        event = build(:event, group: nil)

        expect(event.has_no_project_and_group?).to be true
      end
    end
  end

  def create_push_event(project, user)
    event = create(:push_event, project: project, author: user)

    create(
      :push_event_payload,
      event: event,
      commit_to: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
      commit_count: 0,
      ref: 'master'
    )

    event
  end

  context 'with loose foreign key on events.author_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:user) }
      let_it_be(:model) { create(:event, author: parent) }
    end
  end
end
