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
end
