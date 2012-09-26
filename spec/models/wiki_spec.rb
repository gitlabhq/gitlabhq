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
    it { should validate_presence_of(:user_id) }
  end
end
