# == Schema Information
#
# Table name: snippets
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text(2147483647)
#  author_id  :integer          not null
#  project_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  file_name  :string(255)
#  expires_at :datetime
#  type       :string(255)
#  visibility :string(255)      not null
#

require 'spec_helper'

describe Snippet do
  describe "Associations" do
    it { should belong_to(:author).class_name('User') }
    it { should have_many(:notes).dependent(:destroy) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:author_id) }
  end

  describe "Validation" do
    it { should validate_presence_of(:author) }

    it { should validate_presence_of(:title) }
    it { should ensure_length_of(:title).is_within(0..255) }

    it { should validate_presence_of(:file_name) }
    it { should ensure_length_of(:title).is_within(0..255) }

    it { should validate_presence_of(:content) }
  end

  describe "visibility" do
    it "sets the default visibility" do
      snippet = create(:snippet)
      snippet.visibility.should eq("private")
    end
  end
end
