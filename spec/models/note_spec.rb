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
#  is_award      :boolean          default(FALSE), not null
#

require 'spec_helper'

describe Note, models: true do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:noteable).touch(true) }
    it { is_expected.to belong_to(:author).class_name('User') }

    it { is_expected.to have_many(:todos).dependent(:destroy) }
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

  describe "#all_references" do
    let!(:note1) { create(:note) }
    let!(:note2) { create(:note) }

    it "reads the rendered note body from the cache" do
      expect(Banzai::Renderer).to receive(:render).with(note1.note, pipeline: :note, cache_key: [note1, "note"], project: note1.project)
      expect(Banzai::Renderer).to receive(:render).with(note2.note, pipeline: :note, cache_key: [note2, "note"], project: note2.project)

      note1.all_references
      note2.all_references
    end
  end

  describe '.search' do
    let(:note) { create(:note, note: 'WoW') }

    it 'returns notes with matching content' do
      expect(described_class.search(note.note)).to eq([note])
    end

    it 'returns notes with matching content regardless of the casing' do
      expect(described_class.search('WOW')).to eq([note])
    end
  end

  describe :grouped_awards do
    before do
      create :note, note: "smile", is_award: true
      create :note, note: "smile", is_award: true
    end

    it "returns grouped hash of notes" do
      expect(Note.grouped_awards.keys.size).to eq(3)
      expect(Note.grouped_awards["smile"]).to match_array(Note.all)
    end

    it "returns thumbsup and thumbsdown always" do
      expect(Note.grouped_awards["thumbsup"]).to match_array(Note.none)
      expect(Note.grouped_awards["thumbsdown"]).to match_array(Note.none)
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

    it "returns false" do
      note = build(:note, is_award: true, note: "smiley")
      expect(note.editable?).to be_falsy
    end
  end

  describe "cross_reference_not_visible_for?" do
    let(:private_user)    { create(:user) }
    let(:private_project) { create(:project, namespace: private_user.namespace).tap { |p| p.team << [private_user, :master] } }
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
  end

  describe "set_award!" do
    let(:merge_request) { create :merge_request }

    it "converts aliases to actual name" do
      note = create(:note, note: ":+1:", noteable: merge_request)
      expect(note.reload.note).to eq("thumbsup")
    end

    it "is not an award emoji when comment is on a diff" do
      note = create(:note, note: ":blowfish:", noteable: merge_request, line_code: "11d5d2e667e9da4f7f610f81d86c974b146b13bd_0_2")
      note = note.reload

      expect(note.note).to eq(":blowfish:")
      expect(note.is_award?).to be_falsy
    end
  end

  describe 'clear_blank_line_code!' do
    it 'clears a blank line code before validation' do
      note = build(:note, line_code: ' ')

      expect { note.valid? }.to change(note, :line_code).to(nil)
    end
  end
end
