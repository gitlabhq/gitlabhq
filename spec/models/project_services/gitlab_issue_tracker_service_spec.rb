# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

require 'spec_helper'

describe GitlabIssueTrackerService, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end


  describe 'project and issue urls' do
    let(:project) { create(:project) }

    context 'with absolute urls' do
      before do
        GitlabIssueTrackerService.default_url_options[:script_name] = "/gitlab/root"
        @service = project.create_gitlab_issue_tracker_service(active: true)
      end

      after do
        @service.destroy!
      end

      it 'should give the correct path' do
        expect(@service.project_url).to eq("http://localhost/gitlab/root/#{project.path_with_namespace}/issues")
        expect(@service.new_issue_url).to eq("http://localhost/gitlab/root/#{project.path_with_namespace}/issues/new")
        expect(@service.issue_url(432)).to eq("http://localhost/gitlab/root/#{project.path_with_namespace}/issues/432")
      end
    end

    context 'with relative urls' do
      before do
        GitlabIssueTrackerService.default_url_options[:script_name] = "/gitlab/root"
        @service = project.create_gitlab_issue_tracker_service(active: true)
      end

      after do
        @service.destroy!
      end

      it 'should give the correct path' do
        expect(@service.project_path).to eq("/gitlab/root/#{project.path_with_namespace}/issues")
        expect(@service.new_issue_path).to eq("/gitlab/root/#{project.path_with_namespace}/issues/new")
        expect(@service.issue_path(432)).to eq("/gitlab/root/#{project.path_with_namespace}/issues/432")
      end
    end
  end
end
