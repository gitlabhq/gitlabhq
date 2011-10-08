require 'spec_helper'

describe User do
  describe "Associations" do
    it { should have_many(:projects) }
    it { should have_many(:users_projects) }
    it { should have_many(:issues) }
    it { should have_many(:assigned_issues) }
  end

  describe "Respond to" do
    it { should respond_to(:is_admin?) }
    it { should respond_to(:identifier) }
    it { should respond_to(:name) }
  end

  it "should return valid identifier" do 
    user = User.new(:email => "test@mail.com")
    user.identifier.should == "test_mail.com"
  end
end
# == Schema Information
#
# Table name: users
#
#  id                     :integer         not null, primary key
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(128)     default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer         default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  name                   :string(255)
#  admin                  :boolean         default(FALSE), not null
#

