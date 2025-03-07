# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Note, feature_category: :team_planning do
  include RepoHelpers

  describe 'Concerns' do
    let_it_be(:factory) { :note }
    let_it_be(:discussion_factory) { :discussion_note_on_issue }

    let_it_be(:note1) { create(:note_on_issue) }
    let_it_be(:note2) { create(:note_on_issue) }
    let_it_be(:reply) { create(:note_on_issue, in_reply_to: note1, project: note1.project) }

    let_it_be_with_reload(:discussion_note) { create(:discussion_note_on_issue) }
    let_it_be_with_reload(:discussion_note_2) do
      create(:discussion_note_on_issue, project: discussion_note.project, noteable: discussion_note.noteable)
    end

    let_it_be_with_reload(:discussion_reply) do
      create(:discussion_note_on_issue,
        project: discussion_note.project, noteable: discussion_note.noteable, in_reply_to: discussion_note)
    end

    it_behaves_like 'Notes::ActiveRecord'
    it_behaves_like 'Notes::Discussion'
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:noteable).touch(false) }

    it { is_expected.to have_one(:note_metadata).inverse_of(:note).class_name('Notes::NoteMetadata') }
    it { is_expected.to belong_to(:review).inverse_of(:notes) }
    it { is_expected.to have_many(:events) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Sortable) }
  end

  describe 'default values' do
    it { expect(described_class.new).not_to be_system }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:namespace) }

    context 'when note is on commit' do
      before do
        allow(subject).to receive(:for_commit?).and_return(true)
      end

      it { is_expected.to validate_presence_of(:commit_id) }
      it { is_expected.not_to validate_presence_of(:noteable_id) }
    end

    context 'when note is not on commit' do
      before do
        allow(subject).to receive(:for_commit?).and_return(false)
      end

      it { is_expected.not_to validate_presence_of(:commit_id) }
      it { is_expected.to validate_presence_of(:noteable_id) }
    end

    context 'when noteable and note project differ' do
      subject do
        build(:note, noteable: build_stubbed(:issue), project: build_stubbed(:project))
      end

      it { is_expected.to be_invalid }
    end

    context 'when noteable and note project are the same' do
      subject { create(:note) }

      it { is_expected.to be_valid }
    end

    context 'when project is missing for a project related note' do
      subject { build(:note, project: nil, noteable: build_stubbed(:issue)) }

      it { is_expected.to be_invalid }
    end

    context 'when noteable is a personal snippet' do
      subject { build(:note_on_personal_snippet, noteable: create(:personal_snippet)) }

      it 'is valid without project' do
        is_expected.to be_valid
      end
    end

    context 'when noteable is an abuse report' do
      subject { build(:note, noteable: build_stubbed(:abuse_report), project: nil, namespace: nil) }

      it 'is not valid without project or namespace' do
        is_expected.to be_invalid
      end
    end

    context 'when noteable is a wiki page' do
      subject { build(:note, noteable: build_stubbed(:wiki_page_meta), project: nil, namespace: nil) }

      it 'is not valid without project or namespace' do
        is_expected.to be_invalid
      end
    end

    describe 'max notes limit' do
      let_it_be(:noteable) { create(:issue) }
      let_it_be(:existing_note) { create(:note, project: noteable.project, noteable: noteable) }

      before do
        stub_const('Noteable::MAX_NOTES_LIMIT', 1)
      end

      context 'when creating a system note' do
        subject { build(:system_note, project: noteable.project, noteable: noteable) }

        it { is_expected.to be_valid }
      end

      context 'when creating a user note' do
        subject { build(:note, project: noteable.project, noteable: noteable.reload) }

        it { is_expected.not_to be_valid }
      end

      context 'when updating an existing note on a noteable that already exceeds the limit' do
        subject { existing_note }

        before do
          create(:system_note, project: noteable.project, noteable: noteable)
        end

        it { is_expected.to be_valid }
      end
    end

    describe 'created_at in the past' do
      let_it_be(:noteable) { create(:issue) }

      context 'when creating a note not too much in the past' do
        subject { build(:note, project: noteable.project, noteable: noteable, created_at: '1990-05-06') }

        it { is_expected.to be_valid }
      end

      context 'when creating a note too much in the past' do
        subject { build(:note, project: noteable.project, noteable: noteable, created_at: '1600-05-06') }

        it { is_expected.not_to be_valid }
      end
    end

    describe 'confidentiality' do
      context 'for existing public note' do
        let_it_be(:existing_note) { create(:note) }

        it 'is not possible to change the note to confidential' do
          existing_note.confidential = true

          expect(existing_note).not_to be_valid
          expect(existing_note.errors[:confidential]).to include('can not be changed for existing notes')
        end

        it 'is possible to change confidentiality from nil to false' do
          existing_note.confidential = false

          expect(existing_note).to be_valid
        end
      end

      context 'for existing confidential note' do
        let_it_be(:existing_note) { create(:note, confidential: true) }

        it 'is not possible to change the note to public' do
          existing_note.confidential = false

          expect(existing_note).not_to be_valid
          expect(existing_note.errors[:confidential]).to include('can not be changed for existing notes')
        end
      end

      context 'for a new note' do
        let_it_be(:noteable) { create(:issue) }

        let(:note_params) { { confidential: true, noteable: noteable, project: noteable.project } }

        subject { build(:note, **note_params) }

        it 'allows to create a confidential note for an issue' do
          expect(subject).to be_valid
        end

        context 'when noteable is a merge request' do
          let_it_be(:noteable) { create(:merge_request) }

          it 'can not be set confidential' do
            expect(subject).to be_valid
          end
        end

        context 'when noteable is not allowed to have confidential notes' do
          let_it_be(:noteable) { create(:project_snippet) }

          it 'can not be set confidential' do
            expect(subject).not_to be_valid
            expect(subject.errors[:confidential]).to include('can not be set for this resource')
          end
        end

        context 'when note type is not allowed to be confidential' do
          let(:note_params) { { type: 'DiffNote', confidential: true, noteable: noteable, project: noteable.project } }

          it 'can not be set confidential' do
            expect(subject).not_to be_valid
            expect(subject.errors[:confidential]).to include('can not be set for this type of note')
          end
        end

        context 'when the note is a discussion note' do
          let(:note_params) { { type: 'DiscussionNote', confidential: true, noteable: noteable, project: noteable.project } }

          it { is_expected.to be_valid }
        end

        context 'when replying to a note' do
          let(:note_params) { { confidential: true, noteable: noteable, project: noteable.project } }

          subject { build(:discussion_note, discussion_id: original_note.discussion_id, **note_params) }

          context 'when the note is reply to a confidential note' do
            let_it_be(:original_note) { create(:note, confidential: true, noteable: noteable, project: noteable.project) }

            it { is_expected.to be_valid }
          end

          context 'when the note is reply to a public note' do
            let_it_be(:original_note) { create(:note, noteable: noteable, project: noteable.project) }

            it 'can not be set confidential' do
              expect(subject).not_to be_valid
              expect(subject.errors[:confidential]).to include('reply should have same confidentiality as top-level note')
            end
          end

          context 'when reply note is public but discussion is confidential' do
            let_it_be(:original_note) { create(:note, confidential: true, noteable: noteable, project: noteable.project) }

            let(:note_params) { { noteable: noteable, project: noteable.project } }

            it 'can not be set confidential' do
              expect(subject).not_to be_valid
              expect(subject.errors[:confidential]).to include('reply should have same confidentiality as top-level note')
            end
          end
        end
      end
    end
  end

  describe 'callbacks' do
    describe '#keep_around_commit' do
      let!(:noteable) { create(:issue) }

      it "calls #keep_around_commit normally" do
        note = build(:note, project: noteable.project, noteable: noteable)

        expect(note).to receive(:keep_around_commit)

        note.save!
      end

      it "skips #keep_around_commit if 'skip_keep_around_commits' is true" do
        note = build(:note, project: noteable.project, noteable: noteable, skip_keep_around_commits: true)

        expect(note).not_to receive(:keep_around_commit)

        note.save!
      end

      it "skips #keep_around_commit if 'importing' is true" do
        note = build(:note, project: noteable.project, noteable: noteable, importing: true)

        expect(note).not_to receive(:keep_around_commit)

        note.save!
      end
    end

    describe '#notify_after_create' do
      it 'calls #after_note_created on the noteable' do
        noteable = create(:issue)
        note = build(:note, project: noteable.project, noteable: noteable)

        expect(note).to receive(:notify_after_create).and_call_original
        expect(note.noteable).to receive(:after_note_created).with(note)

        note.save!
      end
    end

    describe '#notify_after_destroy' do
      it 'calls #after_note_destroyed on the noteable' do
        note = create(:note)

        expect(note).to receive(:notify_after_destroy).and_call_original
        expect(note.noteable).to receive(:after_note_destroyed).with(note)

        note.destroy!
      end

      it 'does not error if noteable is nil' do
        note = create(:note)

        expect(note).to receive(:notify_after_destroy).and_call_original
        expect(note).to receive(:noteable).at_least(:once).and_return(nil)
        expect { note.destroy! }.not_to raise_error
      end
    end

    describe 'sets internal flag' do
      subject(:internal) { note.reload.internal }

      let(:note) { create(:note, confidential: confidential, project: issue.project, noteable: issue) }

      let_it_be(:issue) { create(:issue) }

      context 'when confidential is `true`' do
        let(:confidential) { true }

        it { is_expected.to be true }
      end

      context 'when confidential is `false`' do
        let(:confidential) { false }

        it { is_expected.to be false }
      end

      context 'when confidential is `nil`' do
        let(:confidential) { nil }

        it { is_expected.to be false }
      end
    end

    describe '#ensure_namespace_id' do
      context 'for issues' do
        let!(:issue) { create(:issue) }

        it 'copies the namespace_id of the issue' do
          note = build(:note, noteable: issue)

          note.valid?

          expect(note.namespace_id).to eq(issue.namespace_id)
        end
      end

      context 'for group-level work items' do
        let!(:group) { create(:group) }
        let!(:work_item) { create(:work_item, namespace: group) }

        it 'copies the namespace_id of the work item' do
          note = build(:note, noteable: work_item)

          note.valid?

          expect(note.namespace_id).to eq(group.id)
        end
      end

      context 'for a project noteable' do
        let_it_be(:merge_request) { create(:merge_request) }

        it 'copies the project_namespace_id of the project' do
          note = build(:note, noteable: merge_request, project: merge_request.project)

          note.valid?

          expect(note.namespace_id).to eq(merge_request.project.project_namespace_id)
        end

        context 'when noteable is changed' do
          let_it_be(:another_mr) { create(:merge_request) }

          it 'updates the namespace_id' do
            note = create(:note, noteable: merge_request, project: merge_request.project)

            note.noteable = another_mr
            note.project = another_mr.project
            note.valid?

            expect(note.namespace_id).to eq(another_mr.project.project_namespace_id)
          end
        end

        context 'when project is missing' do
          it 'does not raise an exception' do
            note = build(:note, noteable: merge_request, project: nil)

            expect { note.valid? }.not_to raise_error
          end
        end
      end

      context 'for a personal snippet note' do
        let_it_be(:snippet) { create(:personal_snippet) }

        it 'copies the personal namespace_id of the author' do
          note = build(:note, noteable: snippet, project: nil)

          note.valid?

          expect(note.namespace_id).to eq(snippet.author.namespace.id)
        end

        context 'when snippet author is missing' do
          it 'does not raise an exception' do
            note = build(:note, noteable: build(:personal_snippet, author: nil), project: nil)

            expect { note.valid? }.not_to raise_error
          end
        end
      end

      context 'when noteable is missing' do
        it 'does not raise an exception' do
          note = build(:note, noteable: nil, project: nil)

          expect { note.valid? }.not_to raise_error
        end
      end
    end
  end

  describe "Commit notes" do
    before do
      allow(Gitlab::Git::KeepAround).to receive(:execute).and_call_original
    end

    let!(:note) { create(:note_on_commit, note: "+1 from me") }
    let!(:commit) { note.noteable }

    it "is accessible through #noteable" do
      expect(note.commit_id).to eq(commit.id)
      expect(note.noteable).to be_a(Commit)
      expect(note.noteable).to eq(commit)
    end

    it "saves a valid note" do
      expect(note.commit_id).to eq(commit.id)
      note.noteable == commit
    end

    it "is recognized by #for_commit?" do
      expect(note).to be_for_commit
    end

    it "keeps the commit around" do
      repo = note.project.repository

      expect(repo.ref_exists?("refs/keep-around/#{commit.id}")).to be_truthy
    end

    it 'does not generate N+1 queries for participants', :request_store do
      def retrieve_participants
        commit.notes_with_associations.map(&:participants).to_a
      end

      # Project authorization checks are cached, establish a baseline
      retrieve_participants

      control = ActiveRecord::QueryRecorder.new do
        retrieve_participants
      end

      create(:note_on_commit, project: note.project, note: 'another note', noteable_id: commit.id)

      expect { retrieve_participants }.not_to exceed_query_limit(control)
    end
  end

  describe 'authorization' do
    before do
      @p1 = create(:project)
      @p2 = create(:project)
      @u1 = create(:user)
      @u2 = create(:user)
      @u3 = create(:user)
    end

    describe 'read' do
      before do
        @p1.project_members.create!(user: @u2, access_level: ProjectMember::GUEST)
        @p2.project_members.create!(user: @u3, access_level: ProjectMember::GUEST)
      end

      it { expect(Ability.allowed?(@u1, :read_note, @p1)).to be_falsey }
      it { expect(Ability.allowed?(@u2, :read_note, @p1)).to be_truthy }
      it { expect(Ability.allowed?(@u3, :read_note, @p1)).to be_falsey }
    end

    describe 'write' do
      before do
        @p1.project_members.create!(user: @u2, access_level: ProjectMember::DEVELOPER)
        @p2.project_members.create!(user: @u3, access_level: ProjectMember::DEVELOPER)
      end

      it { expect(Ability.allowed?(@u1, :create_note, @p1)).to be_falsey }
      it { expect(Ability.allowed?(@u2, :create_note, @p1)).to be_truthy }
      it { expect(Ability.allowed?(@u3, :create_note, @p1)).to be_falsey }
    end

    describe 'admin' do
      before do
        @p1.project_members.create!(user: @u1, access_level: ProjectMember::REPORTER)
        @p1.project_members.create!(user: @u2, access_level: ProjectMember::MAINTAINER)
        @p2.project_members.create!(user: @u3, access_level: ProjectMember::MAINTAINER)
      end

      it { expect(Ability.allowed?(@u1, :admin_note, @p1)).to be_falsey }
      it { expect(Ability.allowed?(@u2, :admin_note, @p1)).to be_truthy }
      it { expect(Ability.allowed?(@u3, :admin_note, @p1)).to be_falsey }
    end
  end

  it_behaves_like 'an editable mentionable' do
    subject { create :note, noteable: issue, project: issue.project }

    let(:issue) { create(:issue, project: create(:project, :repository)) }
    let(:backref_text) { issue.gfm_reference }
    let(:set_mentionable_text) { ->(txt) { subject.note = txt } }
  end

  describe '#note_html' do
    shared_examples 'note that parses work item references' do
      it 'parses the work item reference' do
        html_link = Nokogiri::HTML.fragment(note.note_html).css('a').first

        expect(html_link.text).to eq(expected_link_text)
        expect(html_link[:href]).to eq(work_item_path)
      end
    end

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:group_work_item) { create(:work_item, :group_level, namespace: group) }
    let_it_be(:project_work_item) { create(:work_item, :task, project: project) }

    context 'when noteable is a group level work item', :aggregate_failures do
      let(:work_item_path) { Gitlab::UrlBuilder.build(group_work_item, only_path: true) }
      let(:expected_link_text) { group_work_item.to_reference }
      let(:note) { create(:note, :on_group_work_item, noteable: group_work_item, note: note_text) }

      context 'when note text contains a group reference (URL)' do
        let(:work_item_path) { Gitlab::UrlBuilder.build(group_work_item) }
        let(:note_text) { work_item_path }

        it_behaves_like 'note that parses work item references'
      end

      context 'when note text contains a group reference (short)' do
        let(:note_text) { group_work_item.to_reference }

        it_behaves_like 'note that parses work item references'
      end

      context 'when note text contains a group reference (full)' do
        let(:note_text) { group_work_item.to_reference(full: true) }

        it_behaves_like 'note that parses work item references'
      end

      context 'when note text contains a project reference (URL)' do
        let(:work_item_path) { Gitlab::UrlBuilder.build(project_work_item) }
        let(:note_text) { work_item_path }
        let(:expected_link_text) { "#{project.path}##{project_work_item.iid}" }

        it_behaves_like 'note that parses work item references'
      end
    end
  end

  describe "#all_references" do
    let!(:note1) { create(:note_on_issue) }
    let!(:note2) { create(:note_on_issue) }

    it "reads the rendered note body from the cache" do
      expect(Banzai::Renderer).to receive(:cache_collection_render)
                                    .with([{
                                      text: note1.note,
                                      context: {
                                        skip_project_check: false,
                                        pipeline: :note,
                                        cache_key: [note1, "note"],
                                        project: note1.project,
                                        rendered: note1.note_html,
                                        author: note1.author
                                      }
                                    }]).and_call_original

      expect(Banzai::Renderer).to receive(:cache_collection_render)
                                    .with([{
                                      text: note2.note,
                                      context: {
                                        skip_project_check: false,
                                        pipeline: :note,
                                        cache_key: [note2, "note"],
                                        project: note2.project,
                                        rendered: note2.note_html,
                                        author: note2.author
                                      }
                                    }]).and_call_original

      note1.all_references.users
      note2.all_references.users
    end
  end

  describe "editable?" do
    it "returns true" do
      note = build(:note)
      expect(note.editable?).to be_truthy
    end

    it "returns false" do
      note = build(:note, system: true)
      expect(note.editable?).to be_falsy
    end
  end

  describe "noteable_author?" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:project) { create(:project, :public, :repository) }

    context 'when note is on commit' do
      let(:noteable) { create(:commit, project: project, author: user1) }

      context 'if user is the noteable author' do
        let(:note) { create(:discussion_note_on_commit, commit_id: noteable.id, project: project, author: user1) }
        let(:diff_note) { create(:diff_note_on_commit, commit_id: noteable.id, project: project, author: user1) }

        it 'returns true' do
          expect(note.noteable_author?(noteable)).to be true
          expect(diff_note.noteable_author?(noteable)).to be true
        end
      end

      context 'if user is not the noteable author' do
        let(:note) { create(:discussion_note_on_commit, commit_id: noteable.id, project: project, author: user2) }
        let(:diff_note) { create(:diff_note_on_commit, commit_id: noteable.id, project: project, author: user2) }

        it 'returns false' do
          expect(note.noteable_author?(noteable)).to be false
          expect(diff_note.noteable_author?(noteable)).to be false
        end
      end
    end

    context 'when note is on issue' do
      let(:noteable) { create(:issue, project: project, author: user1) }

      context 'if user is the noteable author' do
        let(:note) { create(:note, noteable: noteable, author: user1, project: project) }

        it 'returns true' do
          expect(note.noteable_author?(noteable)).to be true
        end
      end

      context 'if user is not the noteable author' do
        let(:note) { create(:note, noteable: noteable, author: user2, project: project) }

        it 'returns false' do
          expect(note.noteable_author?(noteable)).to be false
        end
      end
    end
  end

  describe "last_edited_at" do
    let(:timestamp) { Time.current }
    let(:note) { build(:note, last_edited_at: nil, created_at: timestamp, updated_at: timestamp + 5.hours) }

    context "with last_edited_at" do
      it "returns last_edited_at" do
        note.last_edited_at = timestamp

        expect(note.last_edited_at).to eq(timestamp)
      end
    end

    context "without last_edited_at" do
      it "returns updated_at" do
        expect(note.last_edited_at).to eq(timestamp + 5.hours)
      end
    end
  end

  describe "edited?" do
    let(:note) { build(:note, updated_by_id: nil, created_at: Time.current, updated_at: Time.current + 5.hours) }

    context "with updated_by" do
      it "returns true" do
        note.updated_by = build(:user)

        expect(note.edited?).to be_truthy
      end
    end

    context "without updated_by" do
      it "returns false" do
        expect(note.edited?).to be_falsy
      end
    end
  end

  describe '#confidential?' do
    context 'when note is not confidential' do
      context 'when include_noteable is set to true' do
        it 'is true when a noteable is confidential' do
          issue = create(:issue, :confidential)
          note = build(:note, noteable: issue, project: issue.project)

          expect(note.confidential?(include_noteable: true)).to be_truthy
        end
      end

      context 'when include_noteable is not set to true' do
        it 'is false when a noteable is confidential' do
          issue = create(:issue, :confidential)
          note = build(:note, noteable: issue, project: issue.project)

          expect(note.confidential?).to be_falsey
        end
      end

      it 'is false when a noteable is not confidential' do
        issue = create(:issue, confidential: false)
        note = build(:note, noteable: issue, project: issue.project)

        expect(note.confidential?).to be_falsy
      end

      it "is false when noteable can't be confidential" do
        commit_note = build(:note_on_commit)

        expect(commit_note.confidential?).to be_falsy
      end
    end

    context 'when note is confidential' do
      it 'is true even when a noteable is not confidential' do
        issue = create(:issue, confidential: false)
        note = build(:note, :confidential, noteable: issue, project: issue.project)

        expect(note.confidential?).to be_truthy
      end
    end
  end

  describe "#system_note_visible_for?" do
    let(:project) { create(:project, :public) }
    let(:user) { create(:user) }
    let(:guest) { create(:project_member, :guest, project: project, user: create(:user)).user }
    let(:reporter) { create(:project_member, :reporter, project: project, user: create(:user)).user }
    let(:maintainer) { create(:project_member, :maintainer, project: project, user: create(:user)).user }
    let(:non_member) { create(:user) }

    let(:note) { create(:note, project: project) }

    context 'when project is public' do
      it_behaves_like 'users with note access' do
        let(:users) { [reporter, maintainer, guest, non_member, nil] }
      end
    end

    context 'when group is private' do
      let(:project) { create(:project, :private) }

      it_behaves_like 'users with note access' do
        let(:users) { [reporter, maintainer, guest] }
      end

      it 'returns visible but not readable for non-member user' do
        expect(note.system_note_visible_for?(non_member)).to be_truthy
        expect(note.readable_by?(non_member)).to be_falsy
      end

      it 'returns visible but not readable for a nil user' do
        expect(note.system_note_visible_for?(nil)).to be_truthy
        expect(note.readable_by?(nil)).to be_falsy
      end
    end
  end

  describe "#system_note_viewable_by?(user)" do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:note) { create(:note, project: project) }
    let_it_be(:user) { create(:user) }

    let(:action) { "commit" }
    let!(:metadata) { create(:system_note_metadata, note: note, action: action) }

    context "when system_note_metadata is not present" do
      it "returns true" do
        expect(note).to receive(:system_note_metadata).and_return(nil)

        expect(note.send(:system_note_viewable_by?, user)).to be_truthy
      end
    end

    context "system_note_metadata isn't of type 'branch' or 'contact'" do
      it "returns true" do
        expect(note.send(:system_note_viewable_by?, user)).to be_truthy
      end
    end

    context "system_note_metadata is of type 'branch'" do
      let(:action) { "branch" }

      context "user doesn't have :download_code ability" do
        it "returns false" do
          expect(note.send(:system_note_viewable_by?, user)).to be_falsey
        end
      end

      context "user has the :download_code ability" do
        it "returns true" do
          expect(Ability).to receive(:allowed?).with(user, :download_code, note.project).and_return(true)

          expect(note.send(:system_note_viewable_by?, user)).to be_truthy
        end
      end
    end

    context "system_note_metadata is of type 'contact'" do
      let(:action) { "contact" }

      context "user doesn't have :read_crm_contact ability" do
        it "returns false" do
          expect(note.send(:system_note_viewable_by?, user)).to be_falsey
        end
      end

      context "user has the :read_crm_contact ability" do
        it "returns true" do
          expect(Ability).to receive(:allowed?).with(user, :read_crm_contact, note.project.group).and_return(true)

          expect(note.send(:system_note_viewable_by?, user)).to be_truthy
        end
      end
    end
  end

  describe "system_note_visible_for?" do
    let_it_be(:private_user)    { create(:user) }
    let_it_be(:private_project) { create(:project, namespace: private_user.namespace) { |p| p.add_maintainer(private_user) } }
    let_it_be(:private_issue)   { create(:issue, project: private_project) }

    let_it_be(:ext_proj)  { create(:project, :public) }
    let_it_be(:ext_issue) { create(:issue, project: ext_proj) }

    shared_examples "checks references" do
      it "returns false" do
        expect(note.system_note_visible_for?(ext_issue.author)).to be_falsy
      end

      it "returns true" do
        expect(note.system_note_visible_for?(private_user)).to be_truthy
      end

      it "returns true if user visible reference count set" do
        note.user_visible_reference_count = 1
        note.total_reference_count = 1

        expect(note).not_to receive(:reference_mentionables)
        expect(note.system_note_visible_for?(ext_issue.author)).to be_truthy
      end

      it "returns false if user visible reference count set but does not match total reference count" do
        note.user_visible_reference_count = 1
        note.total_reference_count = 2

        expect(note).not_to receive(:reference_mentionables)
        expect(note.system_note_visible_for?(ext_issue.author)).to be_falsy
      end

      it "returns false if ref count is 0" do
        note.user_visible_reference_count = 0

        expect(note).not_to receive(:reference_mentionables)
        expect(note.system_note_visible_for?(ext_issue.author)).to be_falsy
      end
    end

    context "when there is one reference in note" do
      let(:note) do
        create :note,
          noteable: ext_issue, project: ext_proj,
          note: "mentioned in issue #{private_issue.to_reference(ext_proj)}",
          system: true
      end

      it_behaves_like "checks references"
    end

    context "when there is a reference to a label" do
      let_it_be(:private_label) { create(:label, project: private_project) }

      let(:note) do
        create :note,
          noteable: ext_issue, project: ext_proj,
          note: "added label #{private_label.to_reference(ext_proj)}",
          system: true
      end

      let!(:system_note_metadata) { create(:system_note_metadata, note: note, action: :label) }

      it_behaves_like "checks references"
    end

    context "when there are two references in note" do
      let_it_be(:ext_issue2) { create(:issue, project: ext_proj) }

      let(:note) do
        create :note,
          noteable: ext_issue2, project: ext_proj,
          note: "mentioned in issue #{private_issue.to_reference(ext_proj)} and " \
                "public issue #{ext_issue.to_reference(ext_proj)}",
          system: true
      end

      it_behaves_like "checks references"
    end

    context "when there is a private issue and user reference" do
      let_it_be(:ext_issue2) { create(:issue, project: ext_proj) }

      let(:note) do
        create :note,
          noteable: ext_issue2, project: ext_proj,
          note: "mentioned in #{private_issue.to_reference(ext_proj)} and pinged user #{private_user.to_reference}",
          system: true
      end

      it_behaves_like "checks references"
    end

    context "when there is a publicly visible user reference" do
      let(:note) do
        create :note,
          noteable: ext_issue, project: ext_proj,
          note: "mentioned in #{ext_proj.first_owner.to_reference}",
          system: true
      end

      it "returns true for other users" do
        expect(note.system_note_visible_for?(ext_issue.author)).to be_truthy
      end

      it "returns true for anonymous users" do
        expect(note.system_note_visible_for?(nil)).to be_truthy
      end
    end

    context 'when referenced resource is not present' do
      let(:note) do
        create :note, noteable: ext_issue, project: ext_proj, note: "mentioned in merge request !1", system: true
      end

      it "returns false" do
        expect(note.system_note_visible_for?(private_user)).to be_falsey
      end

      it "returns false if user visible reference count set" do
        note.user_visible_reference_count = 0
        note.total_reference_count = 0

        expect(note).not_to receive(:reference_mentionables)
        expect(note.system_note_visible_for?(ext_issue.author)).to be_falsey
      end
    end
  end

  describe '#system_note_with_references?' do
    it 'falsey for user-generated notes' do
      note = build_stubbed(:note, system: false)

      expect(note.system_note_with_references?).to be_falsy
    end

    context 'when the note might contain cross references' do
      SystemNoteMetadata.new.cross_reference_types.each do |type|
        context "with #{type}" do
          let(:note) { build_stubbed(:note, :system) }
          let!(:metadata) { build_stubbed(:system_note_metadata, note: note, action: type) }

          it 'delegates to the cross-reference regex' do
            expect(note).to receive(:matches_cross_reference_regex?).and_return(false)

            note.system_note_with_references?
          end
        end
      end
    end

    context 'when the note cannot contain cross references' do
      let(:commit_note) { build(:note, note: 'mentioned in 1312312313 something else.', system: true) }
      let(:label_note) { build(:note, note: 'added ~2323232323', system: true) }

      it 'scan for a `mentioned in` prefix' do
        expect(commit_note.system_note_with_references?).to be_truthy
        expect(label_note.system_note_with_references?).to be_falsy
      end
    end

    context 'when system note metadata is not present' do
      let(:note) { build(:note, :system) }

      before do
        allow(note).to receive(:system_note_metadata).and_return(nil)
      end

      it 'delegates to the system note service' do
        expect(SystemNotes::IssuablesService).to receive(:cross_reference?).with(note.note)

        note.system_note_with_references?
      end
    end

    context 'with a system note' do
      let(:issue)     { create(:issue, project: create(:project, :repository)) }
      let(:note)      { create(:system_note, note: "test", noteable: issue, project: issue.project) }

      shared_examples 'system_note_metadata includes note action' do
        it 'delegates to the cross-reference regex' do
          expect(note).to receive(:matches_cross_reference_regex?)

          note.system_note_with_references?
        end
      end

      context 'with :label action' do
        let!(:metadata) { create(:system_note_metadata, note: note, action: :label) }

        it_behaves_like 'system_note_metadata includes note action'

        it { expect(note.system_note_with_references?).to be_falsy }

        context 'with cross reference label note' do
          let(:label) { create(:label, project: issue.project) }
          let(:note) { create(:system_note, note: "added #{label.to_reference} label", noteable: issue, project: issue.project) }

          it { expect(note.system_note_with_references?).to be_truthy }
        end
      end

      context 'with :milestone action' do
        let!(:metadata) { create(:system_note_metadata, note: note, action: :milestone) }

        it_behaves_like 'system_note_metadata includes note action'

        it { expect(note.system_note_with_references?).to be_falsy }

        context 'with cross reference milestone note' do
          let(:milestone) { create(:milestone, project: issue.project) }
          let(:note) { create(:system_note, note: "added #{milestone.to_reference} milestone", noteable: issue, project: issue.project) }

          it { expect(note.system_note_with_references?).to be_truthy }
        end
      end
    end
  end

  describe 'all_referenced_mentionables_allowed?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue) }

    RSpec.shared_examples 'does not generate N+1 queries for reference parsing' do
      it 'does not generate N+1 queries for reference parsing', :request_store do
        ref1 = milestone1.to_reference(issue.project, format: :name, full: true, absolute_path: true)
        ref2 = milestone2.to_reference(issue.project, format: :name, full: true, absolute_path: true)
        ref3 = milestone3.to_reference(issue.project, format: :name, full: true, absolute_path: true)

        text = "mentioned in #{ref1}"
        note = create(:note, :system, noteable: issue, note: text, project: issue.project)

        note.system_note_visible_for?(user)

        text = "mentioned in #{ref1} and #{ref2}"
        note.update!(note: text)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          note.system_note_visible_for?(user)
        end

        text = "mentioned in #{ref1} and #{ref2} and #{ref3}"
        note.update!(note: text)

        expect do
          note.system_note_visible_for?(user)
        end.to issue_same_number_of_queries_as(control).or_fewer
      end
    end

    context 'with a project level milestone' do
      let_it_be(:milestone1) { create(:milestone, project: create(:project, :private)) }
      let_it_be(:milestone2) { create(:milestone, project: create(:project, :private)) }
      let_it_be(:milestone3) { create(:milestone, project: create(:project, :private)) }
      let_it_be(:milestone_event) { create(:resource_milestone_event, issue: issue, milestone: milestone1) }
      let_it_be(:note) { MilestoneNote.from_event(milestone_event, resource: issue, resource_parent: issue.project) }

      it { expect(note.system_note_visible_for?(user)).to be false }

      it_behaves_like 'does not generate N+1 queries for reference parsing'
    end

    context 'with a group level milestone' do
      let_it_be(:milestone1) { create(:milestone, group: create(:group, :private)) }
      let_it_be(:milestone2) { create(:milestone, group: create(:group, :private)) }
      let_it_be(:milestone3) { create(:milestone, group: create(:group, :private)) }
      let_it_be(:milestone_event) { create(:resource_milestone_event, issue: issue, milestone: milestone1) }
      let_it_be(:note) { MilestoneNote.from_event(milestone_event, resource: issue, resource_parent: issue.project) }

      it { expect(note.system_note_visible_for?(user)).to be false }

      it_behaves_like 'does not generate N+1 queries for reference parsing'
    end
  end

  describe 'clear_blank_line_code!' do
    it 'clears a blank line code before validation' do
      note = build(:note, line_code: ' ')

      expect { note.valid? }.to change(note, :line_code).to(nil)
    end
  end

  describe '#participants' do
    it 'includes the note author' do
      project = create(:project, :public)
      issue = create(:issue, project: project)
      note = create(:note_on_issue, noteable: issue, project: project)

      expect(note.participants).to include(note.author)
    end
  end

  describe '#check_for_spam' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:group)   { create(:group, :public) }
    let(:issue)     { create(:issue, project: project) }
    let(:note)      { create(:note, note: "test", noteable: issue, project: project) }
    let(:note_text) { 'content changed' }

    subject do
      note.assign_attributes(note: note_text)
      note.check_for_spam?(user: note.author)
    end

    before do
      allow(issue).to receive(:group).and_return(group)
    end

    context 'when note is public' do
      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when note is public and spammable attributes are not changed' do
      let(:note_text) { 'test' }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'when project does not exist' do
      before do
        allow(note).to receive(:project).and_return(nil)
      end

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when project is not public' do
      before do
        allow(project).to receive(:public?).and_return(false)
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'when group is not public' do
      before do
        allow(group).to receive(:public?).and_return(false)
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'when note is confidential' do
      before do
        allow(note).to receive(:confidential?).and_return(true)
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'when noteable is confidential' do
      before do
        allow(issue).to receive(:confidential?).and_return(true)
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'when noteable is not public' do
      before do
        allow(issue).to receive(:public?).and_return(false)
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'when note is a system note' do
      before do
        allow(note).to receive(:system?).and_return(true)
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end

  describe ".grouped_diff_discussions" do
    let!(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.project }
    let!(:active_diff_note1) { create(:diff_note_on_merge_request, project: project, noteable: merge_request) }
    let!(:active_diff_note2) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, in_reply_to: active_diff_note1) }
    let!(:active_diff_note3) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: active_position2) }
    let!(:outdated_diff_note1) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: outdated_position) }
    let!(:outdated_diff_note2) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, in_reply_to: outdated_diff_note1) }

    let(:active_position2) do
      Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 13,
        diff_refs: project.commit(sample_commit.id).diff_refs
      )
    end

    let(:outdated_position) do
      Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 9,
        diff_refs: project.commit("874797c3a73b60d2187ed6e2fcabd289ff75171e").diff_refs
      )
    end

    context 'active diff discussions' do
      subject { merge_request.notes.grouped_diff_discussions }

      it "includes active discussions" do
        discussions = subject.values.flatten

        expect(discussions.count).to eq(2)
        expect(discussions.map(&:id)).to eq([active_diff_note1.discussion_id, active_diff_note3.discussion_id])
        expect(discussions.all?(&:active?)).to be true

        expect(discussions.first.notes).to eq([active_diff_note1, active_diff_note2])
        expect(discussions.last.notes).to eq([active_diff_note3])
      end

      it "doesn't include outdated discussions" do
        expect(subject.values.flatten.map(&:id)).not_to include(outdated_diff_note1.discussion_id)
      end

      it "groups the discussions by line code" do
        expect(subject[active_diff_note1.line_code].first.id).to eq(active_diff_note1.discussion_id)
        expect(subject[active_diff_note3.line_code].first.id).to eq(active_diff_note3.discussion_id)
      end

      context 'with image discussions' do
        let(:merge_request2) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project, title: "Added images and changes") }
        let(:image_path) { "files/images/ee_repo_logo.png" }
        let(:text_path) { "bar/branch-test.txt" }
        let!(:image_note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request2, position: image_position) }
        let!(:text_note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request2, position: text_position) }

        let(:image_position) do
          Gitlab::Diff::Position.new(
            old_path: image_path,
            new_path: image_path,
            width: 100,
            height: 100,
            x: 1,
            y: 1,
            position_type: "image",
            diff_refs: merge_request2.diff_refs
          )
        end

        let(:text_position) do
          Gitlab::Diff::Position.new(
            old_path: text_path,
            new_path: text_path,
            old_line: nil,
            new_line: 2,
            position_type: "text",
            diff_refs: merge_request2.diff_refs
          )
        end

        it "groups image discussions by file identifier" do
          diff_discussion = DiffDiscussion.new([image_note])

          discussions = merge_request2.notes.grouped_diff_discussions

          expect(discussions.size).to eq(2)
          expect(discussions[image_note.diff_file.new_path]).to include(diff_discussion)
        end

        it "groups text discussions by line code" do
          diff_discussion = DiffDiscussion.new([text_note])

          discussions = merge_request2.notes.grouped_diff_discussions

          expect(discussions.size).to eq(2)
          expect(discussions[text_note.line_code]).to include(diff_discussion)
        end
      end
    end

    context 'diff discussions for older diff refs' do
      subject { merge_request.notes.grouped_diff_discussions(diff_refs) }

      context 'for diff refs a discussion was created at' do
        let(:diff_refs) { active_position2.diff_refs }

        it "includes discussions that were created then" do
          discussions = subject.values.flatten

          expect(discussions.count).to eq(1)

          discussion = discussions.first

          expect(discussion.id).to eq(active_diff_note3.discussion_id)
          expect(discussion.active?).to be true
          expect(discussion.active?(diff_refs)).to be false
          expect(discussion.created_at_diff?(diff_refs)).to be true

          expect(discussion.notes).to eq([active_diff_note3])
        end

        it "groups the discussions by original line code" do
          expect(subject[active_diff_note3.original_line_code].first.id).to eq(active_diff_note3.discussion_id)
        end
      end

      context 'for diff refs a discussion was last active at' do
        let(:diff_refs) { outdated_position.diff_refs }

        it "includes discussions that were last active" do
          discussions = subject.values.flatten

          expect(discussions.count).to eq(1)

          discussion = discussions.first

          expect(discussion.id).to eq(outdated_diff_note1.discussion_id)
          expect(discussion.active?).to be false
          expect(discussion.active?(diff_refs)).to be true
          expect(discussion.created_at_diff?(diff_refs)).to be true

          expect(discussion.notes).to eq([outdated_diff_note1, outdated_diff_note2])
        end

        it "groups the discussions by line code" do
          expect(subject[outdated_diff_note1.line_code].first.id).to eq(outdated_diff_note1.discussion_id)
        end
      end
    end
  end

  describe '.simple_sorts' do
    it 'does not contain name sorts' do
      expect(described_class.simple_sorts.grep(/name/)).to be_empty
    end
  end

  describe '.cherry_picked_merge_requests' do
    it 'returns merge requests that match the given merge commit' do
      note = create(:track_mr_picking_note, commit_id: '456abc')

      create(:track_mr_picking_note, project: create(:project), commit_id: '456def')

      expect(MergeRequest.id_in(described_class.cherry_picked_merge_requests('456abc'))).to eq([note.noteable])
    end
  end

  describe '#for_work_item?' do
    it 'returns true for a work item' do
      expect(build(:note_on_work_item).for_work_item?).to be true
    end

    it 'returns false for an issue' do
      expect(build(:note_on_issue).for_work_item?).to be false
    end
  end

  describe '#for_project_snippet?' do
    it 'returns true for a project snippet note' do
      expect(build(:note_on_project_snippet).for_project_snippet?).to be true
    end

    it 'returns false for a personal snippet note' do
      expect(build(:note_on_personal_snippet).for_project_snippet?).to be false
    end
  end

  describe '#for_personal_snippet?' do
    it 'returns false for a project snippet note' do
      expect(build(:note_on_project_snippet).for_personal_snippet?).to be_falsy
    end

    it 'returns true for a personal snippet note' do
      expect(build(:note_on_personal_snippet).for_personal_snippet?).to be_truthy
    end
  end

  describe '#for_wiki_page?' do
    it 'returns true for a wiki_page' do
      expect(build(:note_on_wiki_page).for_wiki_page?).to be_truthy
    end
  end

  describe '#for_design' do
    it 'is true when the noteable is a design' do
      note = build(:note, noteable: build(:design))

      expect(note).to be_for_design
    end
  end

  describe '#to_ability_name' do
    it 'returns note' do
      expect(build(:note).to_ability_name).to eq('note')
    end
  end

  describe '#noteable_ability_name' do
    it 'returns snippet for a project snippet note' do
      expect(build(:note_on_project_snippet).noteable_ability_name).to eq('snippet')
    end

    it 'returns snippet for a personal snippet note' do
      expect(build(:note_on_personal_snippet).noteable_ability_name).to eq('snippet')
    end

    it 'returns merge_request for an MR note' do
      expect(build(:note_on_merge_request).noteable_ability_name).to eq('merge_request')
    end

    it 'returns issue for an issue note' do
      expect(build(:note_on_issue).noteable_ability_name).to eq('issue')
    end

    it 'returns commit for a commit note' do
      expect(build(:note_on_commit).noteable_ability_name).to eq('commit')
    end

    it 'returns alert_management_alert for an alert note' do
      expect(build(:note_on_alert).noteable_ability_name).to eq('alert_management_alert')
    end

    it 'returns wiki page for a wiki page note' do
      expect(build(:note_on_wiki_page).noteable_ability_name).to eq('wiki_page')
    end
  end

  describe '#cache_markdown_field' do
    let(:html) { '<p>some html</p>' }

    before do
      allow(Banzai::Renderer).to receive(:cacheless_render_field).and_call_original
    end

    context 'note for a project snippet' do
      let(:snippet) { create(:project_snippet) }
      let(:note) { create(:note_on_project_snippet, project: snippet.project, noteable: snippet) }

      it 'skips project check' do
        expect(Banzai::Renderer).to receive(:cacheless_render_field)
          .with(note, :note, { skip_project_check: false })

        note.update!(note: html)
      end
    end

    context 'note for a personal snippet' do
      let(:snippet) { create(:personal_snippet) }
      let(:note) { create(:note_on_personal_snippet, noteable: snippet) }

      it 'does not skip project check' do
        expect(Banzai::Renderer).to receive(:cacheless_render_field)
          .with(note, :note, { skip_project_check: true })

        note.update!(note: html)
      end
    end
  end

  describe '#can_be_discussion_note?' do
    context 'for a note on a merge request' do
      it 'returns true' do
        note = build(:note_on_merge_request)

        expect(note.can_be_discussion_note?).to be_truthy
      end
    end

    context 'for a note on an issue' do
      it 'returns true' do
        note = build(:note_on_issue)

        expect(note.can_be_discussion_note?).to be_truthy
      end
    end

    context 'for a note on a commit' do
      it 'returns true' do
        note = build(:note_on_commit, project: create(:project, :repository))

        expect(note.can_be_discussion_note?).to be_truthy
      end
    end

    context 'for a note on a snippet' do
      it 'returns true' do
        note = build(:note_on_project_snippet)

        expect(note.can_be_discussion_note?).to be_truthy
      end
    end

    context 'for a diff note on merge request' do
      it 'returns false' do
        note = build(:diff_note_on_merge_request)

        expect(note.can_be_discussion_note?).to be_falsey
      end
    end

    context 'for a diff note on commit' do
      it 'returns false' do
        note = build(:diff_note_on_commit, project: create(:project, :repository))

        expect(note.can_be_discussion_note?).to be_falsey
      end
    end

    context 'for a discussion note' do
      it 'returns false' do
        note = build(:discussion_note_on_merge_request)

        expect(note.can_be_discussion_note?).to be_falsey
      end
    end
  end

  describe '#discussion_class' do
    let(:note) { build(:note_on_commit) }
    let(:merge_request) { create(:merge_request) }

    context 'when the note is displayed out of context' do
      it 'returns OutOfContextDiscussion' do
        expect(note.discussion_class(merge_request)).to be(OutOfContextDiscussion)
      end
    end

    context 'when the note is displayed in the original context' do
      it 'returns IndividualNoteDiscussion' do
        expect(note.discussion_class(note.noteable)).to be(IndividualNoteDiscussion)
      end
    end
  end

  describe '#part_of_discussion?' do
    context 'for a diff note' do
      let(:note) { build(:diff_note_on_commit) }

      it 'returns true' do
        expect(note.part_of_discussion?).to be_truthy
      end
    end
  end

  describe '#references' do
    context 'when part of a discussion' do
      it 'references all earlier notes in the discussion' do
        first_note = create(:discussion_note_on_issue)
        second_note = create(:discussion_note_on_issue, in_reply_to: first_note)
        third_note = create(:discussion_note_on_issue, in_reply_to: second_note)
        create(:discussion_note_on_issue, in_reply_to: third_note)

        expect(third_note.references).to eq([first_note.noteable, first_note, second_note])
      end
    end

    context 'when not part of a discussion' do
      subject { create(:note) }

      let(:note) { create(:note, in_reply_to: subject) }

      it 'returns the noteable' do
        expect(note.references).to eq([note.noteable])
      end
    end
  end

  describe 'broadcasting note changes' do
    let_it_be(:issue) { create(:issue) }

    let(:note) { build(:note, project: issue.project, noteable: issue) }

    it 'broadcasts an Action Cable event for the noteable' do
      expect(Noteable::NotesChannel).to receive(:broadcast_to).with(note.noteable, event: 'updated')

      note.save!
    end

    it 'broadcast an Action Cable event for the noteable when note is destroyed' do
      note.save!

      expect(Noteable::NotesChannel).to receive(:broadcast_to).with(note.noteable, event: 'updated')

      note.destroy!
    end

    context 'when issuable real_time_notes is disabled' do
      it 'does not broadcast an Action Cable event' do
        allow(note.noteable).to receive(:real_time_notes_enabled?).and_return(false)

        expect(Noteable::NotesChannel).not_to receive(:broadcast_to)

        note.save!
      end
    end

    context 'for merge requests' do
      let_it_be(:merge_request) { create(:merge_request) }

      context 'when adding a note to the MR' do
        let(:note) { build(:note, noteable: merge_request, project: merge_request.project) }

        it 'broadcasts an Action Cable event for the MR' do
          expect(Noteable::NotesChannel).to receive(:broadcast_to).with(merge_request, event: 'updated')

          note.save!
        end
      end

      context 'when adding a note to a commit on the MR' do
        let(:note) { build(:note_on_commit, commit_id: merge_request.commits.first.id, project: merge_request.project) }

        it 'broadcasts an Action Cable event for the MR' do
          expect(Noteable::NotesChannel).to receive(:broadcast_to).with(merge_request, event: 'updated')

          note.save!
        end
      end
    end
  end

  describe '#with_notes_filter' do
    let!(:comment) { create(:note) }
    let!(:system_note) { create(:note, system: true) }

    subject { described_class.with_notes_filter(filter) }

    context 'when notes filter is nil' do
      let(:filter) { nil }

      it { is_expected.to include(comment, system_note) }
    end

    context 'when notes filter is set to all notes' do
      let(:filter) { UserPreference::NOTES_FILTERS[:all_notes] }

      it { is_expected.to include(comment, system_note) }
    end

    context 'when notes filter is set to only comments' do
      let(:filter) { UserPreference::NOTES_FILTERS[:only_comments] }

      it { is_expected.to include(comment) }
      it { is_expected.not_to include(system_note) }
    end
  end

  describe '#parent' do
    it 'returns project for project notes' do
      project = create(:project)
      note = create(:note_on_issue, project: project)

      expect(note.resource_parent).to eq(project)
    end

    it 'returns nil for personal snippet note' do
      note = create(:note_on_personal_snippet)

      expect(note.resource_parent).to be_nil
    end
  end

  describe 'scopes' do
    let_it_be(:note1) { create(:note, note: 'Test 345') }
    let_it_be(:note2) { create(:note, note: 'Test 789') }

    describe '.for_note_or_capitalized_note' do
      it 'returns the expected matching note' do
        notes = described_class.for_note_or_capitalized_note('Test 345')

        expect(notes.count).to eq(1)
        expect(notes.first.id).to eq(note1.id)
      end

      it 'returns the expected capitalized note' do
        notes = described_class.for_note_or_capitalized_note('test 345')

        expect(notes.count).to eq(1)
        expect(notes.first.id).to eq(note1.id)
      end

      it 'does not support pattern matching' do
        notes = described_class.for_note_or_capitalized_note('test%')

        expect(notes.count).to eq(0)
      end
    end

    describe '.like_note_or_capitalized_note' do
      it 'returns the expected matching note' do
        notes = described_class.like_note_or_capitalized_note('Test 345')

        expect(notes.count).to eq(1)
        expect(notes.first.id).to eq(note1.id)
      end

      it 'returns the expected capitalized note' do
        notes = described_class.like_note_or_capitalized_note('test 345')

        expect(notes.count).to eq(1)
        expect(notes.first.id).to eq(note1.id)
      end

      it 'supports pattern matching' do
        notes = described_class.like_note_or_capitalized_note('test%')

        expect(notes.count).to eq(2)
        expect(notes.first.id).to eq(note1.id)
        expect(notes.second.id).to eq(note2.id)
      end
    end

    describe '.with_suggestions' do
      it 'returns the correct note' do
        note_with_suggestion = create(:note, suggestions: [create(:suggestion)])
        note_without_suggestion = create(:note)

        expect(described_class.with_suggestions).to include(note_with_suggestion)
        expect(described_class.with_suggestions).not_to include(note_without_suggestion)
      end
    end

    describe '.inc_relations_for_view' do
      subject { note.noteable.notes.inc_relations_for_view(noteable) }

      context 'when noteable can not have diffs' do
        let_it_be(:note) { create(:note_on_issue) }
        let(:noteable) { note.noteable }

        it 'does not include additional associations' do
          expect { subject.reload }.to match_query_count(0).for_model(NoteDiffFile).and(
            match_query_count(0).for_model(DiffNotePosition))
        end

        context 'when noteable is not set' do
          let(:noteable) { nil }

          it 'includes additional diff associations' do
            expect { subject.reload }.to match_query_count(1).for_model(NoteDiffFile).and(
              match_query_count(1).for_model(DiffNotePosition))
          end
        end
      end

      context 'when noteable can have diffs' do
        let_it_be(:note) { create(:note_on_commit) }
        let(:noteable) { note.noteable }

        it 'includes additional diff associations' do
          expect { subject.reload }.to match_query_count(1).for_model(NoteDiffFile).and(
            match_query_count(1).for_model(DiffNotePosition))
        end
      end
    end

    describe '.without_hidden' do
      subject { described_class.without_hidden }

      context 'when a note with a banned author exists' do
        let_it_be(:banned_user) { create(:banned_user).user }
        let_it_be(:banned_note) { create(:note, author: banned_user) }

        context 'when the :hidden_notes feature is disabled' do
          before do
            stub_feature_flags(hidden_notes: false)
          end

          it { is_expected.to include(banned_note, note1) }
        end

        context 'when the :hidden_notes feature is enabled' do
          before do
            stub_feature_flags(hidden_notes: true)
          end

          it { is_expected.not_to include(banned_note) }
          it { is_expected.to include(note1) }
        end
      end
    end

    describe '.authored_by' do
      subject(:notes_by_author) { described_class.authored_by(author) }

      let(:author) { create(:user) }

      it 'returns the notes with the matching author' do
        note = create(:note, author: author)
        create(:note)

        expect(notes_by_author).to contain_exactly(note)
      end

      context 'With ID integer' do
        subject(:notes_by_author) { described_class.authored_by(author.id) }

        it 'returns the notes with the matching author' do
          note = create(:note, author: author)
          create(:note)

          expect(notes_by_author).to contain_exactly(note)
        end
      end
    end
  end

  describe 'banzai_render_context' do
    let(:project) { build(:project_empty_repo) }

    subject(:context) { noteable.banzai_render_context(:title) }

    context 'when noteable is a merge request' do
      let(:noteable) { build :merge_request, target_project: project, source_project: project }

      it 'sets the label_url_method in the context' do
        expect(context[:label_url_method]).to eq(:project_merge_requests_url)
      end
    end

    context 'when noteable is an issue' do
      let(:noteable) { build :issue, project: project }

      it 'sets the label_url_method in the context' do
        expect(context[:label_url_method]).to eq(:project_issues_url)
      end
    end

    context 'when noteable is a personal snippet' do
      let(:noteable) { build(:personal_snippet) }

      it 'sets the parent user in the context' do
        expect(context[:user]).to eq(noteable.author)
      end
    end
  end

  describe '#parent_user' do
    it 'returns the author of a personal snippet' do
      note = build(:note_on_personal_snippet)
      expect(note.parent_user).to eq(note.noteable.author)
    end

    it 'returns nil for project snippet' do
      note = build(:note_on_project_snippet)
      expect(note.parent_user).to be_nil
    end

    it 'returns nil when noteable is not a snippet' do
      note = build(:note_on_issue)
      expect(note.parent_user).to be_nil
    end
  end

  describe '#skip_notification?' do
    subject(:skip_notification?) { note.skip_notification? }

    context 'when there is no review' do
      let(:note) { build(:note) }

      it { is_expected.to be_falsey }
    end

    context 'when the review exists' do
      let(:note) { build(:note, :with_review) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#attachment' do
    it 'is cleaned up correctly when project is destroyed' do
      note = create(:note_on_issue, :with_attachment)

      attachment = note.attachment

      note.project.destroy!

      expect(attachment).not_to be_exist
    end
  end

  describe '#post_processed_cache_key' do
    let(:note) { build(:note) }

    it 'returns cache key and author cache key by default' do
      expect(note.post_processed_cache_key).to eq("#{note.cache_key}:#{note.author.cache_key}:#{note.project.team.human_max_access(note.author_id)}")
    end

    context 'when note has no author' do
      let(:note) { build(:note, author: nil) }

      it 'returns cache key only' do
        expect(note.post_processed_cache_key).to eq("#{note.cache_key}:")
      end
    end

    context 'when note has redacted_note_html' do
      let(:redacted_note_html) { 'redacted note html' }

      before do
        note.redacted_note_html = redacted_note_html
      end

      it 'returns cache key with redacted_note_html sha' do
        expect(note.post_processed_cache_key).to eq("#{note.cache_key}:#{note.author.cache_key}:#{note.project.team.human_max_access(note.author_id)}:#{Digest::SHA1.hexdigest(redacted_note_html)}")
      end
    end
  end

  describe '#commands_changes' do
    let(:note) { build(:note) }

    it 'only returns allowed keys' do
      note.commands_changes = { emoji_award: {}, time_estimate: {}, spend_time: {}, target_project: build(:project) }

      expect(note.commands_changes.keys).to contain_exactly(:emoji_award, :time_estimate, :spend_time)
    end
  end

  describe '#bump_updated_at', :freeze_time do
    it 'sets updated_at to the current timestamp' do
      note = create(:note, updated_at: 1.day.ago)

      note.bump_updated_at
      note.reload

      expect(note.updated_at).to be_like_time(Time.current)
    end

    context 'with legacy edited note' do
      it 'copies updated_at to last_edited_at before bumping the timestamp' do
        note = create(:note, updated_at: 1.day.ago, updated_by: create(:user), last_edited_at: nil)

        note.bump_updated_at
        note.reload

        expect(note.last_edited_at).to be_like_time(1.day.ago)
        expect(note.updated_at).to be_like_time(Time.current)
      end
    end
  end

  describe '#issuable_ability_name' do
    subject { note.issuable_ability_name }

    context 'when not confidential note' do
      let(:note) { build(:note) }

      it { is_expected.to eq :read_note }
    end

    context 'when confidential note' do
      let(:note) { build(:note, :confidential) }

      it { is_expected.to eq :read_internal_note }
    end
  end

  describe '#exportable_record?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:noteable) { create(:issue, project: project) }

    subject { note.exportable_record?(user) }

    context 'when not a system note' do
      let(:note) { build(:note, noteable: noteable) }

      it { is_expected.to be_truthy }
    end

    context 'with system note' do
      let(:note) { build(:system_note, project: project, noteable: noteable) }

      it 'returns `false` when the user cannot read the note' do
        is_expected.to be_falsey
      end

      context 'when user can read the note' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#uploads_sharding_key' do
    it 'returns namespace_id' do
      namespace = build_stubbed(:namespace)
      note = build_stubbed(:note, namespace: namespace)

      expect(note.uploads_sharding_key).to eq(namespace_id: namespace.id)
    end
  end
end
