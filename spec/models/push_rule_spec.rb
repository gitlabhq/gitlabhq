require 'spec_helper'

describe PushRule do
  describe "Associations" do
    it { should belong_to(:project) }
  end

  describe "Validation" do
    it { should validate_presence_of(:project) }
    it { should validate_numericality_of(:max_file_size).is_greater_than_or_equal_to(0).only_integer }
  end
end
