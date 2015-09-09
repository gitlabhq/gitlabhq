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
#  updated_by_id :integer
#

require 'spec_helper'

describe Note do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:noteable) }
    it { is_expected.to belong_to(:author).class_name('User') }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:note) }
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '#votable?' do
    it 'is true for issue notes' do
      note = build(:note_on_issue)
      expect(note).to be_votable
    end

    it 'is true for merge request notes' do
      note = build(:note_on_merge_request)
      expect(note).to be_votable
    end

    it 'is false for merge request diff notes' do
      note = build(:note_on_merge_request_diff)
      expect(note).not_to be_votable
    end

    it 'is false for commit notes' do
      note = build(:note_on_commit)
      expect(note).not_to be_votable
    end

    it 'is false for commit diff notes' do
      note = build(:note_on_commit_diff)
      expect(note).not_to be_votable
    end
  end

  describe 'voting score' do
    it 'recognizes a neutral note' do
      note = build(:votable_note, note: 'This is not a +1 note')
      expect(note).not_to be_upvote
      expect(note).not_to be_downvote
    end

    it 'recognizes a neutral emoji note' do
      note = build(:votable_note, note: "I would :+1: this, but I don't want to")
      expect(note).not_to be_upvote
      expect(note).not_to be_downvote
    end

    it 'recognizes a +1 note' do
      note = build(:votable_note, note: '+1 for this')
      expect(note).to be_upvote
    end

    it 'recognizes a +1 emoji as a vote' do
      note = build(:votable_note, note: ':+1: for this')
      expect(note).to be_upvote
    end

    it 'recognizes a thumbsup emoji as a vote' do
      note = build(:votable_note, note: ':thumbsup: for this')
      expect(note).to be_upvote
    end

    it 'recognizes a -1 note' do
      note = build(:votable_note, note: '-1 for this')
      expect(note).to be_downvote
    end

    it 'recognizes a -1 emoji as a vote' do
      note = build(:votable_note, note: ':-1: for this')
      expect(note).to be_downvote
    end

    it 'recognizes a thumbsdown emoji as a vote' do
      note = build(:votable_note, note: ':thumbsdown: for this')
      expect(note).to be_downvote
    end
  end

  describe "Commit notes" do
    let!(:note) { create(:note_on_commit, note: "+1 from me") }
    let!(:commit) { note.noteable }

    it "should be accessible through #noteable" do
      expect(note.commit_id).to eq(commit.id)
      expect(note.noteable).to be_a(Commit)
      expect(note.noteable).to eq(commit)
    end

    it "should save a valid note" do
      expect(note.commit_id).to eq(commit.id)
      note.noteable == commit
    end

    it "should be recognized by #for_commit?" do
      expect(note).to be_for_commit
    end
  end

  describe "Commit diff line notes" do
    let!(:note) { create(:note_on_commit_diff, note: "+1 from me") }
    let!(:commit) { note.noteable }

    it "should save a valid note" do
      expect(note.commit_id).to eq(commit.id)
      expect(note.noteable.id).to eq(commit.id)
    end

    it "should be recognized by #for_diff_line?" do
      expect(note).to be_for_diff_line
    end

    it "should be recognized by #for_commit_diff_line?" do
      expect(note).to be_for_commit_diff_line
    end

    it "should not be votable" do
      expect(note).not_to be_votable
    end
  end

  describe 'authorization' do
    before do
      @p1 = create(:project)
      @p2 = create(:project)
      @u1 = create(:user)
      @u2 = create(:user)
      @u3 = create(:user)
      @abilities = Six.new
      @abilities << Ability
    end

    describe 'read' do
      before do
        @p1.project_members.create(user: @u2, access_level: ProjectMember::GUEST)
        @p2.project_members.create(user: @u3, access_level: ProjectMember::GUEST)
      end

      it { expect(@abilities.allowed?(@u1, :read_note, @p1)).to be_falsey }
      it { expect(@abilities.allowed?(@u2, :read_note, @p1)).to be_truthy }
      it { expect(@abilities.allowed?(@u3, :read_note, @p1)).to be_falsey }
    end

    describe 'write' do
      before do
        @p1.project_members.create(user: @u2, access_level: ProjectMember::DEVELOPER)
        @p2.project_members.create(user: @u3, access_level: ProjectMember::DEVELOPER)
      end

      it { expect(@abilities.allowed?(@u1, :create_note, @p1)).to be_falsey }
      it { expect(@abilities.allowed?(@u2, :create_note, @p1)).to be_truthy }
      it { expect(@abilities.allowed?(@u3, :create_note, @p1)).to be_falsey }
    end

    describe 'admin' do
      before do
        @p1.project_members.create(user: @u1, access_level: ProjectMember::REPORTER)
        @p1.project_members.create(user: @u2, access_level: ProjectMember::MASTER)
        @p2.project_members.create(user: @u3, access_level: ProjectMember::MASTER)
      end

      it { expect(@abilities.allowed?(@u1, :admin_note, @p1)).to be_falsey }
      it { expect(@abilities.allowed?(@u2, :admin_note, @p1)).to be_truthy }
      it { expect(@abilities.allowed?(@u3, :admin_note, @p1)).to be_falsey }
    end
  end

  it_behaves_like 'an editable mentionable' do
    subject { create :note, noteable: issue, project: project }

    let(:project) { create(:project) }
    let(:issue) { create :issue, project: project }
    let(:backref_text) { issue.gfm_reference }
    let(:set_mentionable_text) { ->(txt) { subject.note = txt } }
  end

  describe :search do
    let!(:note) { create(:note, note: "WoW") }

    it { expect(Note.search('wow')).to include(note) }
  end
end
