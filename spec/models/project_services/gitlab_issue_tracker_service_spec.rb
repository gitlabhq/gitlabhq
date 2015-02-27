# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#  template   :boolean          default(FALSE)
#
require 'spec_helper'

describe GitlabIssueTrackerService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end


  describe 'project and issue urls' do
    let(:project) { create(:project) }

    context 'with absolute urls' do
      before do
        @service = project.create_gitlab_issue_tracker_service(active: true)
      end

      after do
        @service.destroy!
      end

      it 'should give the correct path' do
        expect(@service.project_url).to eq("/#{project.path_with_namespace}/issues")
        expect(@service.new_issue_url).to eq("/#{project.path_with_namespace}/issues/new")
        expect(@service.issue_url(432)).to eq("/#{project.path_with_namespace}/issues/432")
      end
    end

    context 'with enabled relative urls' do
      before do
        Settings.gitlab.stub(:relative_url_root).and_return("/gitlab/root")
        @service = project.create_gitlab_issue_tracker_service(active: true)
      end

      after do
        @service.destroy!
      end

      it 'should give the correct path' do
        expect(@service.project_url).to eq("/gitlab/root/#{project.path_with_namespace}/issues")
        expect(@service.new_issue_url).to eq("/gitlab/root/#{project.path_with_namespace}/issues/new")
        expect(@service.issue_url(432)).to eq("/gitlab/root/#{project.path_with_namespace}/issues/432")
      end
    end
  end
end
