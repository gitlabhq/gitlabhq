require 'spec_helper'

describe User do
  describe "Associations" do
    it { should have_many(:projects) }
    it { should have_many(:users_projects).dependent(:destroy) }
    it { should have_many(:issues).dependent(:destroy) }
    it { should have_many(:assigned_issues).dependent(:destroy) }
    it { should have_many(:merge_requests).dependent(:destroy) }
    it { should have_many(:assigned_merge_requests).dependent(:destroy) }
    it { should have_many(:notes).dependent(:destroy) }
  end

  describe "Respond to" do
    it { should respond_to(:is_admin?) }
    it { should respond_to(:identifier) }
    it { should respond_to(:name) }
    it { should respond_to(:private_token) }
  end

  it "should return valid identifier" do
    user = User.new(email: "test@mail.com")
    user.identifier.should == "test_mail_com"
  end

  it "should return identifier without + sign" do
    user = User.new(email: "test+foo@mail.com")
    user.identifier.should == "test_foo_mail_com"
  end

  it "should execute callback when force_random_password specified" do
    user = User.new(email: "test@mail.com", force_random_password: true)
    user.should_receive(:generate_password)
    user.save
  end

  it "should not generate password by default" do
    user = Factory(:user, password: 'abcdefg', password_confirmation: 'abcdefg')
    user.password.should == 'abcdefg'
  end

  it "should generate password when forcing random password" do
    Devise.stub(:friendly_token).and_return('123456789')
    user = User.create(email: "test1@mail.com", force_random_password: true)
    user.password.should == user.password_confirmation
    user.password.should == '12345678'
  end

  it "should have authentication token" do
    user = Factory(:user)
    user.authentication_token.should_not == ""
  end
end
