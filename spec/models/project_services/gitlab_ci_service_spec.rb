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

describe GitlabCiService do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:service_hook) }
  end

  describe 'validations' do
    context 'active' do
      before { allow(subject).to receive(:activated?).and_return(true) }

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to allow_value('ewf9843kdnfdfs89234n').for(:token) }
      it { is_expected.to allow_value('http://ci.example.com/project/1').for(:project_url) }
      it { is_expected.not_to allow_value('token with spaces').for(:token) }
      it { is_expected.not_to allow_value('token/with%spaces').for(:token) }
      it { is_expected.not_to allow_value('this is not url').for(:project_url) }
      it { is_expected.not_to allow_value('http//noturl').for(:project_url) }
      it { is_expected.not_to allow_value('ftp://ci.example.com/projects/3').for(:project_url) }
    end

    context 'inactive' do
      before { allow(subject).to receive(:activated?).and_return(false) }

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.to allow_value('ewf9843kdnfdfs89234n').for(:token) }
      it { is_expected.to allow_value('http://ci.example.com/project/1').for(:project_url) }
      it { is_expected.to allow_value('token with spaces').for(:token) }
      it { is_expected.to allow_value('ftp://ci.example.com/projects/3').for(:project_url) }
    end
  end

  describe 'commits methods' do
    before do
      @service = GitlabCiService.new
      allow(@service).to receive_messages(
        service_hook: true,
        project_url: 'http://ci.gitlab.org/projects/2',
        token: 'verySecret'
      )
    end

    describe :commit_status_path do
      it { expect(@service.commit_status_path("2ab7834c", 'master')).to eq("http://ci.gitlab.org/projects/2/refs/master/commits/2ab7834c/status.json?token=verySecret")}
      it { expect(@service.commit_status_path("issue#2", 'master')).to eq("http://ci.gitlab.org/projects/2/refs/master/commits/issue%232/status.json?token=verySecret")}
    end

    describe :build_page do
      it { expect(@service.build_page("2ab7834c", 'master')).to eq("http://ci.gitlab.org/projects/2/refs/master/commits/2ab7834c")}
      it { expect(@service.build_page("issue#2", 'master')).to eq("http://ci.gitlab.org/projects/2/refs/master/commits/issue%232")}
    end

    describe "execute" do
      let(:user)    { create(:user, username: 'username') }
      let(:project) { create(:project, name: 'project') }
      let(:push_sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }

      it "calls ci_yaml_file" do
        service_hook = double
        expect(service_hook).to receive(:execute)
        expect(@service).to receive(:service_hook).and_return(service_hook)
        expect(@service).to receive(:ci_yaml_file).with(push_sample_data[:checkout_sha])

        @service.execute(push_sample_data)
      end
    end
  end

  describe "Fork registration" do
    before do
      @old_project = create(:empty_project)
      @project = create(:empty_project)
      @user = create(:user)

      @service = GitlabCiService.new
      allow(@service).to receive_messages(
        service_hook: true,
        project_url: 'http://ci.gitlab.org/projects/2',
        token: 'verySecret',
        project: @old_project
      )
    end

    it "performs http reuquest to ci" do
      stub_request(:post, "http://ci.gitlab.org/api/v1/forks")
      @service.fork_registration(@project, @user.private_token)
    end
  end
end
