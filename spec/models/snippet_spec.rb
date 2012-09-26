require 'spec_helper'

describe Snippet do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:author).class_name('User') }
    it { should have_many(:notes).dependent(:destroy) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:author_id) }
    it { should_not allow_mass_assignment_of(:project_id) }
  end

  describe "Validation" do
    it { should validate_presence_of(:author_id) }
    it { should validate_presence_of(:project_id) }

    it { should validate_presence_of(:title) }
    it { should ensure_length_of(:title).is_within(0..255) }

    it { should validate_presence_of(:file_name) }
    it { should ensure_length_of(:title).is_within(0..255) }

    it { should validate_presence_of(:content) }
    it { should ensure_length_of(:content).is_within(0..10_000) }
  end
end
