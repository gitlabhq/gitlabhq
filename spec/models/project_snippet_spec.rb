# == Schema Information
#
# Table name: snippets
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  author_id  :integer          not null
#  project_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  file_name  :string(255)
#  expires_at :datetime
#

require 'spec_helper'

describe ProjectSnippet do
  describe "Associations" do
    it { should belong_to(:project) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:project_id) }
  end

  describe "Validation" do
    it { should validate_presence_of(:project) }
  end
end
