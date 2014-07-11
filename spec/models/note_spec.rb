# == Schema Information
#
# Table name: notes
#
#  id            :integer          not null, primary key
#  note          :text
#  noteable_type :string(255)
#  author_id     :integer
#  created_at    :datetime
#  updated_at    :datetime
#  project_id    :integer
#  attachment    :string(255)
#  line_code     :string(255)
#  commit_id     :string(255)
#  noteable_id   :integer
#  system        :boolean          default(FALSE), not null
#  st_diff       :text
#

require 'spec_helper'

describe Note do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:noteable) }
    it { should belong_to(:author).class_name('User') }
  end

  describe "Mass assignment" do
  end

  describe "Validation" do
    it { should validate_presence_of(:note) }
    it { should validate_presence_of(:project) }
  end

  describe "Voting score" do
    let(:project) { create(:project) }

    it "recognizes a neutral note" do
      note = create(:votable_note, note: "This is not a +1 note")
      note.should_not be_upvote
      note.should_not be_downvote
    end

    it "recognizes a neutral emoji note" do
      note = build(:votable_note, note: "I would :+1: this, but I don't want to")
      note.should_not be_upvote
      note.should_not be_downvote
    end

    it "recognizes a +1 note" do
      note = create(:votable_note, note: "+1 for this")
      note.should be_upvote
    end

    it "recognizes a +1 emoji as a vote" do
      note = build(:votable_note, note: ":+1: for this")
      note.should be_upvote
    end

    it "recognizes a thumbsup emoji as a vote" do
      note = build(:votable_note, note: ":thumbsup: for this")
      note.should be_upvote
    end

    it "recognizes a -1 note" do
      note = create(:votable_note, note: "-1 for this")
      note.should be_downvote
    end

    it "recognizes a -1 emoji as a vote" do
      note = build(:votable_note, note: ":-1: for this")
      note.should be_downvote
    end

    it "recognizes a thumbsdown emoji as a vote" do
      note = build(:votable_note, note: ":thumbsdown: for this")
      note.should be_downvote
    end
  end

  let(:project) { create(:project) }

  describe "Commit notes" do
    let!(:note) { create(:note_on_commit, note: "+1 from me") }
    let!(:commit) { note.noteable }

    it "should be accessible through #noteable" do
      note.commit_id.should == commit.id
      note.noteable.should be_a(Commit)
      note.noteable.should == commit
    end

    it "should save a valid note" do
      note.commit_id.should == commit.id
      note.noteable == commit
    end

    it "should be recognized by #for_commit?" do
      note.should be_for_commit
    end

    it "should not be votable" do
      note.should_not be_votable
    end
  end

  describe "Commit diff line notes" do
    let!(:note) { create(:note_on_commit_diff, note: "+1 from me") }
    let!(:commit) { note.noteable }

    it "should save a valid note" do
      note.commit_id.should == commit.id
      note.noteable.id.should == commit.id
    end

    it "should be recognized by #for_diff_line?" do
      note.should be_for_diff_line
    end

    it "should be recognized by #for_commit_diff_line?" do
      note.should be_for_commit_diff_line
    end

    it "should not be votable" do
      note.should_not be_votable
    end
  end

  describe "Issue notes" do
    let!(:note) { create(:note_on_issue, note: "+1 from me") }

    it "should not be votable" do
      note.should be_votable
    end
  end

  describe "Merge request notes" do
    let!(:note) { create(:note_on_merge_request, note: "+1 from me") }

    it "should be votable" do
      note.should be_votable
    end
  end

  describe "Merge request diff line notes" do
    let!(:note) { create(:note_on_merge_request_diff, note: "+1 from me") }

    it "should not be votable" do
      note.should_not be_votable
    end
  end

  describe '#create_status_change_note' do
    let(:project) { create(:project) }
    let(:thing) { create(:issue, project: project) }
    let(:author) { create(:user) }
    let(:status) { 'new_status' }

    subject { Note.create_status_change_note(thing, project, author, status, nil) }

    it 'creates and saves a Note' do
      should be_a Note
      subject.id.should_not be_nil
    end

    its(:noteable) { should == thing }
    its(:project) { should == thing.project }
    its(:author) { should == author }
    its(:note) { should =~ /Status changed to #{status}/ }

    it 'appends a back-reference if a closing mentionable is supplied' do
      commit = double('commit', gfm_reference: 'commit 123456')
      n = Note.create_status_change_note(thing, project, author, status, commit)

      n.note.should =~ /Status changed to #{status} by commit 123456/
    end
  end

  describe '#create_assignee_change_note' do
    let(:project) { create(:project) }
    let(:thing) { create(:issue, project: project) }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }

    subject { Note.create_assignee_change_note(thing, project, author, assignee) }

    context 'creates and saves a Note' do
      it { should be_a Note }
      its(:id) { should_not be_nil }
    end

    its(:noteable) { should == thing }
    its(:project) { should == thing.project }
    its(:author) { should == author }
    its(:note) { should =~ /Reassigned to @#{assignee.username}/ }

    context 'assignee is removed' do
      let(:assignee) { nil }

      its(:note) { should =~ /Assignee removed/ }
    end
  end

  describe '#create_cross_reference_note' do
    let(:project)    { create(:project) }
    let(:author)     { create(:user) }
    let(:issue)      { create(:issue, project: project) }
    let(:mergereq)   { create(:merge_request, :simple, target_project: project, source_project: project) }
    let(:commit)     { project.repository.commit }

    # Test all of {issue, merge request, commit} in both the referenced and referencing
    # roles, to ensure that the correct information can be inferred from any argument.

    context 'issue from a merge request' do
      subject { Note.create_cross_reference_note(issue, mergereq, author, project) }

      it { should be_valid }
      its(:noteable) { should == issue }
      its(:project)  { should == issue.project }
      its(:author)   { should == author }
      its(:note) { should == "_mentioned in merge request !#{mergereq.iid}_" }
    end

    context 'issue from a commit' do
      subject { Note.create_cross_reference_note(issue, commit, author, project) }

      it { should be_valid }
      its(:noteable) { should == issue }
      its(:note) { should == "_mentioned in commit #{commit.sha[0..5]}_" }
    end

    context 'merge request from an issue' do
      subject { Note.create_cross_reference_note(mergereq, issue, author, project) }

      it { should be_valid }
      its(:noteable) { should == mergereq }
      its(:project) { should == mergereq.project }
      its(:note) { should == "_mentioned in issue ##{issue.iid}_" }
    end

    context 'commit from a merge request' do
      subject { Note.create_cross_reference_note(commit, mergereq, author, project) }

      it { should be_valid }
      its(:noteable) { should == commit }
      its(:project) { should == project }
      its(:note) { should == "_mentioned in merge request !#{mergereq.iid}_" }
    end

    context 'commit from issue' do
      subject { Note.create_cross_reference_note(commit, issue, author, project) }

      it { should be_valid }
      its(:noteable_type) { should == "Commit" }
      its(:noteable_id) { should be_nil }
      its(:commit_id) { should == commit.id }
      its(:note) { should == "_mentioned in issue ##{issue.iid}_" }
    end
  end

  describe '#cross_reference_exists?' do
    let(:project) { create :project }
    let(:author) { create :user }
    let(:issue) { create :issue }
    let(:commit0) { double 'commit0', gfm_reference: 'commit 123456' }
    let(:commit1) { double 'commit1', gfm_reference: 'commit 654321' }

    before do
      Note.create_cross_reference_note(issue, commit0, author, project)
    end

    it 'detects if a mentionable has already been mentioned' do
      Note.cross_reference_exists?(issue, commit0).should be_true
    end

    it 'detects if a mentionable has not already been mentioned' do
      Note.cross_reference_exists?(issue, commit1).should be_false
    end
  end

  describe '#system?' do
    let(:project) { create(:project) }
    let(:issue)   { create(:issue, project: project) }
    let(:other)   { create(:issue, project: project) }
    let(:author)  { create(:user) }
    let(:assignee) { create(:user) }

    it 'should recognize user-supplied notes as non-system' do
      @note = create(:note_on_issue)
      @note.should_not be_system
    end

    it 'should identify status-change notes as system notes' do
      @note = Note.create_status_change_note(issue, project, author, 'closed', nil)
      @note.should be_system
    end

    it 'should identify cross-reference notes as system notes' do
      @note = Note.create_cross_reference_note(issue, other, author, project)
      @note.should be_system
    end

    it 'should identify assignee-change notes as system notes' do
      @note = Note.create_assignee_change_note(issue, project, author, assignee)
      @note.should be_system
    end
  end

  describe :authorization do
    before do
      @p1 = create(:project)
      @p2 = create(:project)
      @u1 = create(:user)
      @u2 = create(:user)
      @u3 = create(:user)
      @abilities = Six.new
      @abilities << Ability
    end

    describe :read do
      before do
        @p1.users_projects.create(user: @u2, project_access: UsersProject::GUEST)
        @p2.users_projects.create(user: @u3, project_access: UsersProject::GUEST)
      end

      it { @abilities.allowed?(@u1, :read_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :read_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :read_note, @p1).should be_false }
    end

    describe :write do
      before do
        @p1.users_projects.create(user: @u2, project_access: UsersProject::DEVELOPER)
        @p2.users_projects.create(user: @u3, project_access: UsersProject::DEVELOPER)
      end

      it { @abilities.allowed?(@u1, :write_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :write_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :write_note, @p1).should be_false }
    end

    describe :admin do
      before do
        @p1.users_projects.create(user: @u1, project_access: UsersProject::REPORTER)
        @p1.users_projects.create(user: @u2, project_access: UsersProject::MASTER)
        @p2.users_projects.create(user: @u3, project_access: UsersProject::MASTER)
      end

      it { @abilities.allowed?(@u1, :admin_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :admin_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :admin_note, @p1).should be_false }
    end
  end

  it_behaves_like 'an editable mentionable' do
    let(:issue) { create :issue, project: project }
    let(:subject) { create :note, noteable: issue, project: project }
    let(:backref_text) { issue.gfm_reference }
    let(:set_mentionable_text) { ->(txt) { subject.note = txt } }
  end
end
