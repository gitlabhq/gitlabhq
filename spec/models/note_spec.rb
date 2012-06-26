require 'spec_helper'

describe Note do
  let(:project) { Factory :project }
  let!(:commit) { project.commit }

  describe "Associations" do
    it { should belong_to(:project) }
  end

  describe "Validation" do
    it { should validate_presence_of(:note) }
    it { should validate_presence_of(:project) }
  end

  it { Factory.create(:note,
                      :project => project).should be_valid }
  describe "Scopes" do
    it "should have a today named scope that returns ..." do
      Note.today.where_values.should == ["created_at >= '#{Date.today}'"]
    end
  end

  describe "Voting score" do
    let(:project) { Factory(:project) }

    it "recognizes a neutral note" do
      note = Factory(:note, project: project, note: "This is not a +1 note")
      note.should_not be_upvote
    end

    it "recognizes a +1 note" do
      note = Factory(:note, project: project, note: "+1 for this")
      note.should be_upvote
    end

    it "recognizes a -1 note as no vote" do
      note = Factory(:note, project: project, note: "-1 for this")
      note.should_not be_upvote
    end
  end

  describe "Commit notes" do

    before do
      @note = Factory :note,
        :project => project,
        :noteable_id => commit.id,
        :noteable_type => "Commit"
    end

    it "should save a valid note" do
      @note.noteable_id.should == commit.id
      @note.target.id.should == commit.id
    end
  end

  describe "Pre-line commit notes" do
    before do
      @note = Factory :note,
        :project => project,
        :noteable_id => commit.id,
        :noteable_type => "Commit",
        :line_code => "0_16_1"
    end

    it "should save a valid note" do
      @note.noteable_id.should == commit.id
      @note.target.id.should == commit.id
    end
  end

  describe '#create_status_change_note' do
    let(:project)  { Factory.create(:project) }
    let(:thing)    { Factory.create(:issue, :project => project) }
    let(:author)   { Factory(:user) }
    let(:status)   { 'new_status' }

    subject { Note.create_status_change_note(thing, author, status) }

    it 'creates and saves a Note' do
      should be_a Note
      subject.id.should_not be_nil
    end

    its(:noteable) { should == thing }
    its(:project)  { should == thing.project }
    its(:author)   { should == author }
    its(:note)     { should =~ /Status changed to #{status}/ }
  end

  describe :authorization do
    before do
      @p1 = project
      @p2 = Factory :project, :code => "alien", :path => "gitlabhq_1"
      @u1 = Factory :user
      @u2 = Factory :user
      @u3 = Factory :user
      @abilities = Six.new
      @abilities << Ability
    end

    describe :read do
      before do
        @p1.users_projects.create(:user => @u2, :project_access => UsersProject::GUEST)
        @p2.users_projects.create(:user => @u3, :project_access => UsersProject::GUEST)
      end

      it { @abilities.allowed?(@u1, :read_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :read_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :read_note, @p1).should be_false }
    end

    describe :write do
      before do
        @p1.users_projects.create(:user => @u2, :project_access => UsersProject::DEVELOPER)
        @p2.users_projects.create(:user => @u3, :project_access => UsersProject::DEVELOPER)
      end

      it { @abilities.allowed?(@u1, :write_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :write_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :write_note, @p1).should be_false }
    end

    describe :admin do
      before do
        @p1.users_projects.create(:user => @u1, :project_access => UsersProject::REPORTER)
        @p1.users_projects.create(:user => @u2, :project_access => UsersProject::MASTER)
        @p2.users_projects.create(:user => @u3, :project_access => UsersProject::MASTER)
      end

      it { @abilities.allowed?(@u1, :admin_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :admin_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :admin_note, @p1).should be_false }
    end
  end
end
# == Schema Information
#
# Table name: notes
#
#  id            :integer(4)      not null, primary key
#  note          :text
#  noteable_id   :string(255)
#  noteable_type :string(255)
#  author_id     :integer(4)
#  created_at    :datetime        not null
#  updated_at    :datetime        not null
#  project_id    :integer(4)
#  attachment    :string(255)
#  line_code     :string(255)
#

