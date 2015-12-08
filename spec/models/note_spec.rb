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
    subject { create :note, noteable: issue, project: issue.project }

    let(:issue) { create :issue }
    let(:backref_text) { issue.gfm_reference }
    let(:set_mentionable_text) { ->(txt) { subject.note = txt } }
  end

  describe :search do
    let!(:note) { create(:note, note: "WoW") }

    it { expect(Note.search('wow')).to include(note) }
  end

  describe :grouped_awards do
    before do
      create :note, note: "smile", is_award: true
      create :note, note: "smile", is_award: true
    end

    it "returns grouped array of notes" do
      expect(Note.grouped_awards.first.first).to eq("smile")
      expect(Note.grouped_awards.first.last).to match_array(Note.all)
    end
  end
end
