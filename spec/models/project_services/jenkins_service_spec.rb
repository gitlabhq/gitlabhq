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
#

require 'spec_helper'

describe JenkinsService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end
  let(:project) { create(:project) }
  let(:jenkins_params) do
    {
      active: true,
      project: project,
      properties: {
        jenkins_url: 'http://jenkins.example.com/',
        project_name: 'my_project'
      }
    }
  end

  describe 'username validation' do
    before do
      @jenkins_service = JenkinsService.create(
        active: active,
        project: project,
        properties: {
          jenkins_url: 'http://jenkins.example.com/',
          password: 'password',
          username: nil,
        }
      )
    end
    subject { @jenkins_service }

    context 'when the service is active' do
      let(:active) { true }
      it { is_expected.to validate_presence_of :username }
    end

    context 'when the service is inactive' do
      let(:active) { false }
      it { is_expected.not_to validate_presence_of :username }
    end
  end

  describe '#hook_url' do
    before do
      @jenkins_service = JenkinsService.create(
        project: project,
        properties: {
          jenkins_url: jenkins_url,
          project_name: 'my_project'
        }
      )
    end
    subject { @jenkins_service.hook_url }

    context 'when the jenkins_url has no relative path' do
      let(:jenkins_url) { 'http://jenkins.example.com/' }
      it { is_expected.to eq('http://jenkins.example.com/project/my_project') }
    end

    context 'when the jenkins_url has relative path' do
      let(:jenkins_url) { 'http://organization.example.com/jenkins' }
      it { is_expected.to eq('http://organization.example.com/jenkins/project/my_project') }
    end
  end

  describe '#test' do
    it 'returns the right status' do
      user = create(:user, username: 'username')
      project = create(:project, name: 'project')
      push_sample_data = Gitlab::PushDataBuilder.build_sample(project, user)
      jenkins_service = described_class.create(jenkins_params)
      stub_request(:post, jenkins_service.hook_url)

      result = jenkins_service.test(push_sample_data)

      expect(result).to eq({ success: true, result: '' })
    end
  end

  describe '#execute' do
    it 'adds default web hook headers to the request' do
      user = create(:user, username: 'username')
      project = create(:project, name: 'project')
      push_sample_data = Gitlab::PushDataBuilder.build_sample(project, user)
      jenkins_service = described_class.create(jenkins_params)
      stub_request(:post, jenkins_service.hook_url)

      jenkins_service.execute(push_sample_data)

      expect(
        a_request(:post, jenkins_service.hook_url)
          .with(headers: { 'X-Gitlab-Event' => 'Push Hook' })
      ).to have_been_made.once
    end
  end

  describe 'Stored password invalidation' do
    let(:project) { create(:project) }

    context 'when a password was previously set' do
      before do
        @jenkins_service = JenkinsService.create(
          project: project,
          properties: {
            jenkins_url: 'http://jenkins.example.com/',
            username: 'jenkins',
            password: 'password'
          }
        )
      end

      it 'reset password if url changed' do
        @jenkins_service.jenkins_url = 'http://jenkins-edited.example.com/'
        @jenkins_service.save
        expect(@jenkins_service.password).to be_nil
      end

      it 'does not reset password if username changed' do
        @jenkins_service.username = 'some_name'
        @jenkins_service.save
        expect(@jenkins_service.password).to eq('password')
      end

      it 'does not reset password if new url is set together with password, even if it\'s the same password' do
        @jenkins_service.jenkins_url = 'http://jenkins_edited.example.com/'
        @jenkins_service.password = 'password'
        @jenkins_service.save
        expect(@jenkins_service.password).to eq('password')
        expect(@jenkins_service.jenkins_url).to eq('http://jenkins_edited.example.com/')
      end

      it 'should reset password if url changed, even if setter called multiple times' do
        @jenkins_service.jenkins_url = 'http://jenkins1.example.com/'
        @jenkins_service.jenkins_url = 'http://jenkins1.example.com/'
        @jenkins_service.save
        expect(@jenkins_service.password).to be_nil
      end
    end

    context 'when no password was previously set' do
      before do
        @jenkins_service = JenkinsService.create(
          project: create(:project),
          properties: {
            jenkins_url: 'http://jenkins.example.com/',
            username: 'jenkins'
          }
        )
      end

      it 'saves password if new url is set together with password' do
        @jenkins_service.jenkins_url = 'http://jenkins_edited.example.com/'
        @jenkins_service.password = 'password'
        @jenkins_service.save
        expect(@jenkins_service.password).to eq('password')
        expect(@jenkins_service.jenkins_url).to eq('http://jenkins_edited.example.com/')
      end

    end
  end
end
