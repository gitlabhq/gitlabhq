require 'spec_helper'

describe UsersProject do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
  end

  describe "Validation" do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:project_id) }
  end

  describe "Delegate methods" do
    it { should respond_to(:user_name) }
    it { should respond_to(:user_email) }
  end
end
