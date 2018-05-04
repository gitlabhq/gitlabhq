require 'spec_helper'

describe Note do
  include RepoHelpers

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:noteable).touch(false) }
    it { is_expected.to belong_to(:author).class_name('User') }

    it { is_expected.to have_many(:todos) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Participable) }
    it { is_expected.to include_module(Mentionable) }
    it { is_expected.to include_module(Awardable) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:note) }
    it { is_expected.to validate_presence_of(:project) }

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
        build(:note, noteable: build_stubbed(:issue),
                     project: build_stubbed(:project))
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
      subject { build(:note_on_personal_snippet) }

      it 'is valid without project' do
        is_expected.to be_valid
      end
    end
  end

  describe "Commit notes" do
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
      expect(note.project.repository.kept_around?(commit.id)).to be_truthy
    end

    it 'does not generate N+1 queries for participants', :request_store do
      def retrieve_participants
        commit.notes_with_associations.map(&:participants).to_a
      end

      # Project authorization checks are cached, establish a baseline
      retrieve_participants

      control_count = ActiveRecord::QueryRecorder.new do
        retrieve_participants
      end

      create(:note_on_commit, project: note.project, note: 'another note', noteable_id: commit.id)

      expect { retrieve_participants }.not_to exceed_query_limit(control_count)
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
        @p1.project_members.create(user: @u2, access_level: ProjectMember::GUEST)
        @p2.project_members.create(user: @u3, access_level: ProjectMember::GUEST)
      end

      it { expect(Ability.allowed?(@u1, :read_note, @p1)).to be_falsey }
      it { expect(Ability.allowed?(@u2, :read_note, @p1)).to be_truthy }
      it { expect(Ability.allowed?(@u3, :read_note, @p1)).to be_falsey }
    end

    describe 'write' do
      before do
        @p1.project_members.create(user: @u2, access_level: ProjectMember::DEVELOPER)
        @p2.project_members.create(user: @u3, access_level: ProjectMember::DEVELOPER)
      end

      it { expect(Ability.allowed?(@u1, :create_note, @p1)).to be_falsey }
      it { expect(Ability.allowed?(@u2, :create_note, @p1)).to be_truthy }
      it { expect(Ability.allowed?(@u3, :create_note, @p1)).to be_falsey }
    end

    describe 'admin' do
      before do
        @p1.project_members.create(user: @u1, access_level: ProjectMember::REPORTER)
        @p1.project_members.create(user: @u2, access_level: ProjectMember::MASTER)
        @p2.project_members.create(user: @u3, access_level: ProjectMember::MASTER)
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

  describe "confidential?" do
    it "delegates to noteable" do
      issue_note = build(:note, :on_issue)
      confidential_note = build(:note, noteable: create(:issue, confidential: true))

      expect(issue_note.confidential?).to be_falsy
      expect(confidential_note.confidential?).to be_truthy
    end

    it "is falsey when noteable can't be confidential" do
      commit_note = build(:note_on_commit)
      expect(commit_note.confidential?).to be_falsy
    end
  end

  describe "cross_reference_not_visible_for?" do
    let(:private_user)    { create(:user) }
    let(:private_project) { create(:project, namespace: private_user.namespace) { |p| p.add_master(private_user) } }
    let(:private_issue)   { create(:issue, project: private_project) }

    let(:ext_proj)  { create(:project, :public) }
    let(:ext_issue) { create(:issue, project: ext_proj) }

    let(:note) do
      create :note,
        noteable: ext_issue, project: ext_proj,
        note: "mentioned in issue #{private_issue.to_reference(ext_proj)}",
        system: true
    end

    it "returns true" do
      expect(note.cross_reference_not_visible_for?(ext_issue.author)).to be_truthy
    end

    it "returns false" do
      expect(note.cross_reference_not_visible_for?(private_user)).to be_falsy
    end

    it "returns false if user visible reference count set" do
      note.user_visible_reference_count = 1

      expect(note).not_to receive(:reference_mentionables)
      expect(note.cross_reference_not_visible_for?(ext_issue.author)).to be_falsy
    end

    it "returns true if ref count is 0" do
      note.user_visible_reference_count = 0

      expect(note).not_to receive(:reference_mentionables)
      expect(note.cross_reference_not_visible_for?(ext_issue.author)).to be_truthy
    end
  end

  describe '#cross_reference?' do
    it 'falsey for user-generated notes' do
      note = create(:note, system: false)

      expect(note.cross_reference?).to be_falsy
    end

    context 'when the note might contain cross references' do
      SystemNoteMetadata::TYPES_WITH_CROSS_REFERENCES.each do |type|
        let(:note) { create(:note, :system) }
        let!(:metadata) { create(:system_note_metadata, note: note, action: type) }

        it 'delegates to the cross-reference regex' do
          expect(note).to receive(:matches_cross_reference_regex?).and_return(false)

          note.cross_reference?
        end
      end
    end

    context 'when the note cannot contain cross references' do
      let(:commit_note) { build(:note, note: 'mentioned in 1312312313 something else.', system: true) }
      let(:label_note) { build(:note, note: 'added ~2323232323', system: true) }

      it 'scan for a `mentioned in` prefix' do
        expect(commit_note.cross_reference?).to be_truthy
        expect(label_note.cross_reference?).to be_falsy
      end
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

  describe '.find_discussion' do
    let!(:note) { create(:discussion_note_on_merge_request) }
    let!(:note2) { create(:discussion_note_on_merge_request, in_reply_to: note) }
    let(:merge_request) { note.noteable }

    it 'returns a discussion with multiple notes' do
      discussion = merge_request.notes.find_discussion(note.discussion_id)

      expect(discussion).not_to be_nil
      expect(discussion.notes).to match_array([note, note2])
      expect(discussion.first_note.discussion_id).to eq(note.discussion_id)
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

  describe '#for_personal_snippet?' do
    it 'returns false for a project snippet note' do
      expect(build(:note_on_project_snippet).for_personal_snippet?).to be_falsy
    end

    it 'returns true for a personal snippet note' do
      expect(build(:note_on_personal_snippet).for_personal_snippet?).to be_truthy
    end
  end

  describe '#to_ability_name' do
    it 'returns snippet for a project snippet note' do
      expect(build(:note_on_project_snippet).to_ability_name).to eq('snippet')
    end

    it 'returns personal_snippet for a personal snippet note' do
      expect(build(:note_on_personal_snippet).to_ability_name).to eq('personal_snippet')
    end

    it 'returns merge_request for an MR note' do
      expect(build(:note_on_merge_request).to_ability_name).to eq('merge_request')
    end

    it 'returns issue for an issue note' do
      expect(build(:note_on_issue).to_ability_name).to eq('issue')
    end

    it 'returns issue for a commit note' do
      expect(build(:note_on_commit).to_ability_name).to eq('commit')
    end
  end

  describe '#cache_markdown_field' do
    let(:html) { '<p>some html</p>'}

    context 'note for a project snippet' do
      let(:note) { build(:note_on_project_snippet) }

      before do
        expect(Banzai::Renderer).to receive(:cacheless_render_field)
          .with(note, :note, { skip_project_check: false }).and_return(html)

        note.save
      end

      it 'creates a note' do
        expect(note.note_html).to eq(html)
      end
    end

    context 'note for a personal snippet' do
      let(:note) { build(:note_on_personal_snippet) }

      before do
        expect(Banzai::Renderer).to receive(:cacheless_render_field)
          .with(note, :note, { skip_project_check: true }).and_return(html)

        note.save
      end

      it 'creates a note' do
        expect(note.note_html).to eq(html)
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
        note = build(:note_on_commit)

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
        note = build(:diff_note_on_commit)

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

  describe "#discussion_id" do
    let(:note) { create(:note_on_commit) }

    context "when it is newly created" do
      it "has a discussion id" do
        expect(note.discussion_id).not_to be_nil
        expect(note.discussion_id).to match(/\A\h{40}\z/)
      end
    end

    context "when it didn't store a discussion id before" do
      before do
        note.update_column(:discussion_id, nil)
      end

      it "has a discussion id" do
        # The discussion_id is set in `after_initialize`, so `reload` won't work
        reloaded_note = described_class.find(note.id)

        expect(reloaded_note.discussion_id).not_to be_nil
        expect(reloaded_note.discussion_id).to match(/\A\h{40}\z/)
      end
    end

    context 'when the note is displayed out of context' do
      let(:merge_request) { create(:merge_request) }

      it 'overrides the discussion id' do
        expect(note.discussion_id(merge_request)).not_to eq(note.discussion_id)
      end
    end
  end

  describe '#to_discussion' do
    subject { create(:discussion_note_on_merge_request) }
    let!(:note2) { create(:discussion_note_on_merge_request, project: subject.project, noteable: subject.noteable, in_reply_to: subject) }

    it "returns a discussion with just this note" do
      discussion = subject.to_discussion

      expect(discussion.id).to eq(subject.discussion_id)
      expect(discussion.notes).to eq([subject])
    end
  end

  describe "#discussion" do
    let!(:note1) { create(:discussion_note_on_merge_request) }
    let!(:note2) { create(:diff_note_on_merge_request, project: note1.project, noteable: note1.noteable) }

    context 'when the note is part of a discussion' do
      subject { create(:discussion_note_on_merge_request, project: note1.project, noteable: note1.noteable, in_reply_to: note1) }

      it "returns the discussion this note is in" do
        discussion = subject.discussion

        expect(discussion.id).to eq(subject.discussion_id)
        expect(discussion.notes).to eq([note1, subject])
      end
    end

    context 'when the note is not part of a discussion' do
      subject { create(:note) }

      it "returns a discussion with just this note" do
        discussion = subject.discussion

        expect(discussion.id).to eq(subject.discussion_id)
        expect(discussion.notes).to eq([subject])
      end
    end
  end

  describe "#part_of_discussion?" do
    context 'for a regular note' do
      let(:note) { build(:note) }

      it 'returns false' do
        expect(note.part_of_discussion?).to be_falsey
      end
    end

    context 'for a diff note' do
      let(:note) { build(:diff_note_on_commit) }

      it 'returns true' do
        expect(note.part_of_discussion?).to be_truthy
      end
    end

    context 'for a discussion note' do
      let(:note) { build(:discussion_note_on_merge_request) }

      it 'returns true' do
        expect(note.part_of_discussion?).to be_truthy
      end
    end
  end

  describe '#in_reply_to?' do
    context 'for a note' do
      context 'when part of a discussion' do
        subject { create(:discussion_note_on_issue) }
        let(:note) { create(:discussion_note_on_issue, in_reply_to: subject) }

        it 'checks if the note is in reply to the other discussion' do
          expect(subject).to receive(:in_reply_to?).with(note).and_call_original
          expect(subject).to receive(:in_reply_to?).with(note.noteable).and_call_original
          expect(subject).to receive(:in_reply_to?).with(note.to_discussion).and_call_original

          subject.in_reply_to?(note)
        end
      end

      context 'when not part of a discussion' do
        subject { create(:note) }
        let(:note) { create(:note, in_reply_to: subject) }

        it 'checks if the note is in reply to the other noteable' do
          expect(subject).to receive(:in_reply_to?).with(note).and_call_original
          expect(subject).to receive(:in_reply_to?).with(note.noteable).and_call_original

          subject.in_reply_to?(note)
        end
      end
    end

    context 'for a discussion' do
      context 'when part of the same discussion' do
        subject { create(:diff_note_on_merge_request) }
        let(:note) { create(:diff_note_on_merge_request, in_reply_to: subject) }

        it 'returns true' do
          expect(subject.in_reply_to?(note.to_discussion)).to be_truthy
        end
      end

      context 'when not part of the same discussion' do
        subject { create(:diff_note_on_merge_request) }
        let(:note) { create(:diff_note_on_merge_request) }

        it 'returns false' do
          expect(subject.in_reply_to?(note.to_discussion)).to be_falsey
        end
      end
    end

    context 'for a noteable' do
      context 'when a comment on the same noteable' do
        subject { create(:note) }
        let(:note) { create(:note, in_reply_to: subject) }

        it 'returns true' do
          expect(subject.in_reply_to?(note.noteable)).to be_truthy
        end
      end

      context 'when not a comment on the same noteable' do
        subject { create(:note) }
        let(:note) { create(:note) }

        it 'returns false' do
          expect(subject.in_reply_to?(note.noteable)).to be_falsey
        end
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

  describe 'expiring ETag cache' do
    let(:note) { build(:note_on_issue) }

    def expect_expiration(note)
      expect_any_instance_of(Gitlab::EtagCaching::Store)
        .to receive(:touch)
        .with("/#{note.project.namespace.to_param}/#{note.project.to_param}/noteable/issue/#{note.noteable.id}/notes")
    end

    it "expires cache for note's issue when note is saved" do
      expect_expiration(note)

      note.save!
    end

    it "expires cache for note's issue when note is destroyed" do
      expect_expiration(note)

      note.destroy!
    end
  end
end
