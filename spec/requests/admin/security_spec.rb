require 'spec_helper'

describe "Admin::Projects" do
  describe "GET /admin/projects" do
    it { admin_projects_path.should be_allowed_for :admin }
    it { admin_projects_path.should be_denied_for :user }
    it { admin_projects_path.should be_denied_for :visitor }
  end

  describe "GET /admin/users" do
    it { admin_users_path.should be_allowed_for :admin }
    it { admin_users_path.should be_denied_for :user }
    it { admin_users_path.should be_denied_for :visitor }
  end

  describe "GET /admin/emails" do
    it { admin_emails_path.should be_allowed_for :admin }
    it { admin_emails_path.should be_denied_for :user }
    it { admin_emails_path.should be_denied_for :visitor }
  end
end
