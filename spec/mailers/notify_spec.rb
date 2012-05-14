require 'spec_helper'

describe Notify do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  before :all do
    default_url_options[:host] = 'example.com'
  end

  let(:example_email) { 'user@example.com' }

  describe 'new user email' do
    let(:example_password) { 'thisismypassword' }
    let(:example_site_url) { root_url }
    let(:new_user) { Factory.new(:user, :email => example_email, :password => example_password) }

    subject { Notify.new_user_email(new_user, new_user.password) }

    it 'is sent to the new user' do
      should deliver_to new_user.email
    end

    it 'has the correct subject' do
      should have_subject /Account was created for you/
    end

    it 'contains the new user\'s login name' do
      should have_body_text /#{new_user.email}/
    end

    it 'contains the new user\'s password' do
      should have_body_text /#{new_user.password}/
    end

    it 'includes a link to the site' do
      should have_body_text /#{example_site_url}/
    end
  end

  describe 'new issue email' do
    let(:project) { Factory.create(:project) }
    let(:assignee) { Factory.create(:user, :email => example_email) }
    let(:issue) { Factory.create(:issue, :assignee => assignee, :project => project ) }

    subject { Notify.new_issue_email(issue) }

    it 'is sent to the assignee' do
      should deliver_to assignee.email
    end

    it 'has the correct subject' do
      should have_subject /New Issue was created/
    end

    it 'contains a link to the new issue' do
      should have_body_text /#{project_issue_url project, issue}/
    end
  end

  describe 'note wall email' do
    let(:project) { Factory.create(:project) }
    let(:recipient) { Factory.create(:user, :email => example_email) }
    let(:author) { Factory.create(:user) }
    let(:note) { Factory.create(:note, :project => project, :author => author) }
    let(:note_url) { wall_project_url(project, :anchor => "note_#{note.id}") }

    subject { Notify.note_wall_email(recipient, note) }

    it 'is sent to the given recipient' do
      should deliver_to recipient.email
    end

    it 'has the correct subject' do
      should have_subject /#{project.name}/
    end

    it 'contains a link to the wall note' do
      should have_body_text /#{note_url}/
    end
  end
end
