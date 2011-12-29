require 'spec_helper'

describe DeployKey do
  describe "Associations" do
    it { should belong_to(:project) }
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:key) }
  end

  describe "Methods" do
    it { should respond_to :projects }
  end

  it { Factory.create(:key,
                      :project => Factory(:project)).should be_valid }
end
# == Schema Information
#
# Table name: deploy_keys
#
#  id         :integer         not null, primary key
#  project_id    :integer         not null
#  created_at :datetime
#  updated_at :datetime
#  key        :text
#  title      :string(255)
#  identifier :string(255)
#


