require 'spec_helper'

describe GitHook do
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
