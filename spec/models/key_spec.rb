require 'spec_helper'

describe Key do
  describe "Associations" do
    it { should belong_to(:user) or belong_to(:project)  }
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:key) }
  end

  describe "Methods" do
    it { should respond_to :projects }
  end

  context "validation of uniqueness" do

    context "as a deploy key" do
      let(:project) { Factory.create(:project, path: 'alpha', code: 'alpha') }
      let(:another_project) { Factory.create(:project, path: 'beta', code: 'beta') }

      before do
        deploy_key = Factory.create(:key, project: project)
      end

      it "does not accept the same key twice for a project" do
        key = Factory.new(:key, project: project)
        key.should_not be_valid
      end

      it "does accept the same key for another project" do
        key = Factory.new(:key, project: another_project)
        key.should be_valid
      end
    end

    context "as a personal key" do
      let(:user) { Factory.create(:user) }

      it "accepts the key once" do
        Factory.new(:key, user: user).should be_valid
      end

      it "does not accepts the key twice" do
        Factory.create(:key, user: user)
        Factory.new(:key, user: user).should_not be_valid
      end
    end
  end
end
# == Schema Information
#
# Table name: keys
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  key        :text
#  title      :string(255)
#  identifier :string(255)
#  project_id :integer(4)
#

