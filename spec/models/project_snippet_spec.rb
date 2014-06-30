# == Schema Information
#
# Table name: snippets
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  author_id  :integer          not null
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#  file_name  :string(255)
#  expires_at :datetime
#  private    :boolean          default(TRUE), not null
#  type       :string(255)
#

require 'spec_helper'

describe ProjectSnippet do
  describe "Associations" do
    it { should belong_to(:project) }
  end

  describe "Mass assignment" do
  end

  describe "Validation" do
    it { should validate_presence_of(:project) }
  end
end
