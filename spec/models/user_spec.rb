require 'spec_helper'

describe User do
  describe "Associations" do
    it { should have_many(:projects) }
    it { should have_many(:users_projects) }
    it { should have_many(:issues) }
    it { should have_many(:assigned_issues) }
    it { should have_many(:merge_requests) }
    it { should have_many(:assigned_merge_requests) }
  end

  describe "Respond to" do
    it { should respond_to(:is_admin?) }
    it { should respond_to(:identifier) }
    it { should respond_to(:name) }
    it { should respond_to(:private_token) }
  end

  it "should return valid identifier" do
    user = User.new(:email => "test@mail.com")
    user.identifier.should == "test_mail_com"
  end

  it "should execute callback when force_random_password specified" do
    user = User.new(:email => "test@mail.com", :force_random_password => true)
    user.should_receive(:generate_password)
    user.save
  end

  it "should not generate password by default" do
    user = Factory(:user, :password => 'abcdefg', :password_confirmation => 'abcdefg')
    user.password.should == 'abcdefg'
  end

  it "should generate password when forcing random password" do
    Devise.stub(:friendly_token).and_return('123456789')
    user = User.create(:email => "test1@mail.com", :force_random_password => true)
    user.password.should == user.password_confirmation
    user.password.should == '12345678'
  end

  it "should have authentication token" do
    user = Factory(:user)
    user.authentication_token.should_not == ""
  end

  describe "dependent" do
    before do
      @user = Factory :user
      @note = Factory :note,
        :author => @user,
        :project => Factory(:project)
    end

    it "should destroy all notes with user" do
      Note.find_by_id(@note.id).should_not be_nil
      @user.destroy
      Note.find_by_id(@note.id).should be_nil
    end
  end
end
# == Schema Information
#
# Table name: users
#
#  id                     :integer(4)      not null, primary key
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(128)     default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer(4)      default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime        not null
#  updated_at             :datetime        not null
#  name                   :string(255)
#  admin                  :boolean(1)      default(FALSE), not null
#  projects_limit         :integer(4)      default(10)
#  skype                  :string(255)     default(""), not null
#  linkedin               :string(255)     default(""), not null
#  twitter                :string(255)     default(""), not null
#  authentication_token   :string(255)
#  dark_scheme            :boolean(1)      default(FALSE), not null
#  theme_id               :integer(4)      default(1), not null
#  bio                    :string(255)
#  blocked                :boolean(1)      default(FALSE), not null
#

