require 'spec_helper'

describe Note do
  describe "Associations" do
    it { should belong_to(:project) }
  end

  describe "Validation" do
    it { should validate_presence_of(:note) }
    it { should validate_presence_of(:project) }
  end

  it { Factory.create(:note,
                      :project => Factory.create(:project)).should be_valid }

  describe :authorization do
    before do
      @p1 = Factory :project
      @p2 = Factory :project, :code => "alien", :path => "legit_1"
      @u1 = Factory :user
      @u2 = Factory :user
      @u3 = Factory :user
      @abilities = Six.new
      @abilities << Ability
    end

    describe :read do
      before do
        @p1.users_projects.create(:user => @u1, :read => false)
        @p1.users_projects.create(:user => @u2, :read => true)
        @p2.users_projects.create(:user => @u3, :read => true)
      end

      it { @abilities.allowed?(@u1, :read_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :read_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :read_note, @p1).should be_false }
    end

    describe :write do
      before do
        @p1.users_projects.create(:user => @u1, :write => false)
        @p1.users_projects.create(:user => @u2, :write => true)
        @p2.users_projects.create(:user => @u3, :write => true)
      end

      it { @abilities.allowed?(@u1, :write_note, @p1).should be_false }
      it { @abilities.allowed?(@u2, :write_note, @p1).should be_true }
      it { @abilities.allowed?(@u3, :write_note, @p1).should be_false }
    end

    describe :admin do
      before do
        @p1.users_projects.create(:user => @u1, :admin => false)
        @p1.users_projects.create(:user => @u2, :admin => true)
        @p2.users_projects.create(:user => @u3, :admin => true)
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
#  id            :integer         not null, primary key
#  note          :text
#  noteable_id   :string(255)
#  noteable_type :string(255)
#  author_id     :integer
#  created_at    :datetime
#  updated_at    :datetime
#  project_id    :integer
#  attachment    :string(255)
#

