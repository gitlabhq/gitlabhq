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
# Table name: snippets
#
#  id         :integer         not null, primary key
#  title      :string(255)
#  content    :text
#  author_id  :integer         not null
#  project_id :integer         not null
#  created_at :datetime
#  updated_at :datetime
#  file_name  :string(255)
#  expires_at :datetime
#

