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

describe DroneCiService, models: true do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:service_hook) }
  end

  describe 'validations' do
    context 'active' do
      before { allow(subject).to receive(:activated?).and_return(true) }

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:drone_url) }
      it { is_expected.to allow_value('ewf9843kdnfdfs89234n').for(:token) }
      it { is_expected.to allow_value('http://ci.example.com').for(:drone_url) }
      it { is_expected.not_to allow_value('this is not url').for(:drone_url) }
      it { is_expected.not_to allow_value('http//noturl').for(:drone_url) }
      it { is_expected.not_to allow_value('ftp://ci.example.com').for(:drone_url) }
    end

    context 'inactive' do
      before { allow(subject).to receive(:activated?).and_return(false) }

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:drone_url) }
      it { is_expected.to allow_value('ewf9843kdnfdfs89234n').for(:token) }
      it { is_expected.to allow_value('http://drone.example.com').for(:drone_url) }
      it { is_expected.to allow_value('ftp://drone.example.com').for(:drone_url) }
    end
  end

  shared_context :drone_ci_service do
    let(:drone)      { DroneCiService.new }
    let(:project)    { create(:project, name: 'project') }
    let(:path)       { "#{project.namespace.path}/#{project.path}" }
    let(:drone_url)  { 'http://drone.example.com' }
    let(:sha)        { '2ab7834c' }
    let(:branch)     { 'dev' }
    let(:token)      { 'secret' }
    let(:iid)        { rand(1..9999) }

    before(:each) do
      allow(drone).to receive_messages(
        project_id: project.id,
        project: project,
        active: true,
        drone_url: drone_url,
        token: token
      )
    end
  end

  describe "service page/path methods" do
    include_context :drone_ci_service

    # URL's
    let(:commit_page) { "#{drone_url}/gitlab/#{path}/redirect/commits/#{sha}?branch=#{branch}" }
    let(:merge_request_page) { "#{drone_url}/gitlab/#{path}/redirect/pulls/#{iid}" }
    let(:commit_status_path) { "#{drone_url}/gitlab/#{path}/commits/#{sha}?branch=#{branch}&access_token=#{token}" }
    let(:merge_request_status_path) { "#{drone_url}/gitlab/#{path}/pulls/#{iid}?access_token=#{token}" }

    it { expect(drone.build_page(sha, branch)).to eq(commit_page) }
    it { expect(drone.commit_page(sha, branch)).to eq(commit_page) }
    it { expect(drone.merge_request_page(iid, sha, branch)).to eq(merge_request_page) }
    it { expect(drone.commit_status_path(sha, branch)).to eq(commit_status_path) }
    it { expect(drone.merge_request_status_path(iid, sha, branch)).to eq(merge_request_status_path)  }
  end

  describe "execute" do
    include_context :drone_ci_service

    let(:user)    { create(:user, username: 'username') }
    let(:push_sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }

    it do
      service_hook = double
      expect(service_hook).to receive(:execute)
      expect(drone).to receive(:service_hook).and_return(service_hook)

      drone.execute(push_sample_data)
    end
  end
end
