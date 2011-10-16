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
