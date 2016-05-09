require 'spec_helper'

describe ProjectSnippet, models: true do
  describe "Associations" do
    it { is_expected.to belong_to(:project) }
  end

  describe "Mass assignment" do
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:project) }
  end
end
