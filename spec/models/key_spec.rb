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

  it { Factory.create(:key,
                      :user => Factory(:user)).should be_valid }
end
# == Schema Information
#
# Table name: keys
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  key        :text
#  title      :string(255)
#  identifier :string(255)
#  project_id :integer
#

