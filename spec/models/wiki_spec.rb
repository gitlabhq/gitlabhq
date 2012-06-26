require 'spec_helper'

describe Wiki do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:user_id) }
  end

  it { Factory(:wiki).should be_valid }
end
# == Schema Information
#
# Table name: wikis
#
#  id         :integer(4)      not null, primary key
#  title      :string(255)
#  content    :text
#  project_id :integer(4)
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  slug       :string(255)
#  user_id    :integer(4)
#

