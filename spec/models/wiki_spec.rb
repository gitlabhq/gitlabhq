# == Schema Information
#
# Table name: wikis
#
#  id         :integer         not null, primary key
#  title      :string(255)
#  content    :text
#  project_id :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  slug       :string(255)
#  user_id    :integer
#

require 'spec_helper'

describe Wiki do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
    it { should have_many(:notes).dependent(:destroy) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:project_id) }
    it { should_not allow_mass_assignment_of(:user_id) }
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should ensure_length_of(:title).is_within(1..250) }
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:user) }
  end
end
