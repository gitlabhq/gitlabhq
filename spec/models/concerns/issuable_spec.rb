require 'spec_helper'

describe Issue, "Issuable" do
  let(:issue) { create(:issue) }

  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:author) }
    it { should belong_to(:assignee) }
    it { should have_many(:notes).dependent(:destroy) }
  end

  describe "Validation" do
    it { should validate_presence_of(:project) }
    it { should validate_presence_of(:author) }
    it { should validate_presence_of(:title) }
    it { should ensure_length_of(:title).is_at_least(0).is_at_most(255) }
    it { should ensure_inclusion_of(:closed).in_array([true, false]) }
  end

  describe "Scope" do
    it { described_class.should respond_to(:opened) }
    it { described_class.should respond_to(:closed) }
    it { described_class.should respond_to(:assigned) }
  end

  it "has an :author_id_of_changes accessor" do
    issue.should respond_to(:author_id_of_changes)
    issue.should respond_to(:author_id_of_changes=)
  end

  describe ".search" do
    let!(:searchable_issue) { create(:issue, title: "Searchable issue") }

    it "matches by title" do
      described_class.search('able').all.should == [searchable_issue]
    end
  end

  describe "#today?" do
    it "returns true when created today" do
      # Avoid timezone differences and just return exactly what we want
      Date.stub(:today).and_return(issue.created_at.to_date)
      issue.today?.should be_true
    end

    it "returns false when not created today" do
      Date.stub(:today).and_return(Date.yesterday)
      issue.today?.should be_false
    end
  end

  describe "#new?" do
    it "returns true when created today and record hasn't been updated" do
      issue.stub(:today?).and_return(true)
      issue.new?.should be_true
    end

    it "returns false when not created today" do
      issue.stub(:today?).and_return(false)
      issue.new?.should be_false
    end

    it "returns false when record has been updated" do
      issue.stub(:today?).and_return(true)
      issue.touch
      issue.new?.should be_false
    end
  end
end
