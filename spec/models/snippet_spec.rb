require 'spec_helper'

describe Snippet do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:author) }
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:author_id) }
    it { should validate_presence_of(:project_id) }
    it { should validate_presence_of(:file_name) }
    it { should validate_presence_of(:content) }
  end
end
# == Schema Information
#
# Table name: snippets
#
#  id         :integer(4)      not null, primary key
#  title      :string(255)
#  content    :text
#  author_id  :integer(4)      not null
#  project_id :integer(4)      not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  file_name  :string(255)
#  expires_at :datetime
#

