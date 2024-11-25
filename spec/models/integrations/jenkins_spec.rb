# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Jenkins, feature_category: :integrations do
  let_it_be(:project) { create(:project) }
  let(:jenkins_integration) { described_class.new(jenkins_params) }
  let(:jenkins_url) { 'http://jenkins.example.com/' }
  let(:jenkins_hook_url) { jenkins_url + 'project/my_project' }
  let(:jenkins_username) { 'u$er name%2520' }
  let(:jenkins_password) { 'pas$ word' }
  let(:jenkins_authorization) { 'Basic ' + ::Base64.strict_encode64(jenkins_username + ':' + jenkins_password) }
  let(:jenkins_params) do
    {
      active: true,
      project: project,
      properties: {
        password: jenkins_password,
        username: jenkins_username,
        jenkins_url: jenkins_url,
        project_name: 'my_project'
      }
    }
  end

  it_behaves_like Integrations::Base::Ci

  it_behaves_like Integrations::ResetSecretFields do
    let(:integration) { jenkins_integration }
  end

  include_context Integrations::EnableSslVerification do
    let(:integration) { jenkins_integration }
  end

  it_behaves_like Integrations::HasWebHook do
    let(:integration) { jenkins_integration }
    let(:hook_url) { "http://#{ERB::Util.url_encode jenkins_username}:#{ERB::Util.url_encode jenkins_password}@jenkins.example.com/project/my_project" }
  end

  it 'sets the default values', :aggregate_failures do
    expect(jenkins_integration.push_events).to eq(true)
    expect(jenkins_integration.merge_requests_events).to eq(false)
    expect(jenkins_integration.tag_push_events).to eq(false)
  end

  describe 'Validations' do
    let(:jenkins_integration) do
      described_class.create!(
        active: active,
        project: project,
        properties: {
          jenkins_url: 'http://jenkins.example.com/',
          password: 'password',
          username: 'username',
          project_name: 'my_project'
        }
      )
    end

    subject { jenkins_integration }

    context 'when the integration is active' do
      let(:active) { true }

      describe '#username' do
        context 'when password was not touched' do
          before do
            allow(subject).to receive(:password_touched?).and_return(false)
          end

          it { is_expected.not_to validate_presence_of :username }
        end

        context 'when password was touched' do
          before do
            allow(subject).to receive(:password_touched?).and_return(true)
          end

          it { is_expected.to validate_presence_of :username }
        end

        context 'when password is blank' do
          it 'does not validate the username' do
            expect(subject).not_to validate_presence_of :username

            subject.password = ''
            subject.save!
          end
        end
      end

      describe '#password' do
        it 'does not validate the presence of password if username is nil' do
          subject.username = nil

          expect(subject).not_to validate_presence_of(:password)
        end

        it 'validates the presence of password if username is present' do
          subject.username = 'john'

          expect(subject).to validate_presence_of(:password)
        end
      end
    end

    context 'when the integration is inactive' do
      let(:active) { false }

      it { is_expected.not_to validate_presence_of :username }
      it { is_expected.not_to validate_presence_of :password }
    end
  end

  describe '#hook_url' do
    let(:username) { nil }
    let(:password) { nil }
    let(:jenkins_integration) do
      described_class.new(
        project: project,
        properties: {
          jenkins_url: jenkins_url,
          project_name: 'my_project',
          username: username,
          password: password
        }
      )
    end

    subject { jenkins_integration.hook_url }

    context 'when the jenkins_url has no relative path' do
      let(:jenkins_url) { 'http://jenkins.example.com/' }

      it { is_expected.to eq('http://jenkins.example.com/project/my_project') }
    end

    context 'when the jenkins_url has relative path' do
      let(:jenkins_url) { 'http://organization.example.com/jenkins' }

      it { is_expected.to eq('http://organization.example.com/jenkins/project/my_project') }
    end

    context 'userinfo is missing and username and password are set' do
      let(:jenkins_url) { 'http://organization.example.com/jenkins' }
      let(:username) { 'u$ername' }
      let(:password) { 'pas$ word' }

      it { is_expected.to eq('http://u%24ername:pas%24%20word@organization.example.com/jenkins/project/my_project') }
    end

    context 'userinfo is provided and username and password are set' do
      let(:jenkins_url) { 'http://u:p@organization.example.com/jenkins' }
      let(:username) { 'username' }
      let(:password) { 'password' }

      it { is_expected.to eq('http://username:password@organization.example.com/jenkins/project/my_project') }
    end

    context 'userinfo is provided username and password are not set' do
      let(:jenkins_url) { 'http://u:p@organization.example.com/jenkins' }

      it { is_expected.to eq('http://u:p@organization.example.com/jenkins/project/my_project') }
    end
  end

  describe '#test' do
    it 'returns the right status' do
      user = build(:user, username: 'username')
      push_sample_data = Gitlab::DataBuilder::Push.build_sample(project, user)
      jenkins_integration = described_class.create!(jenkins_params)
      stub_request(:post, jenkins_hook_url).with(headers: { 'Authorization' => jenkins_authorization })

      result = jenkins_integration.test(push_sample_data)

      expect(result).to eq({ success: true, result: '' })
    end
  end

  describe '#execute' do
    let(:user) { build(:user, username: 'username') }
    let_it_be(:namespace) { create(:group, :private) }
    let_it_be(:project) { create(:project, :private, name: 'project', namespace: namespace) }
    let(:push_sample_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }
    let(:jenkins_integration) { described_class.create!(jenkins_params) }

    before do
      stub_request(:post, jenkins_hook_url)
    end

    it 'invokes the Jenkins API' do
      jenkins_integration.execute(push_sample_data)

      expect(a_request(:post, jenkins_hook_url)).to have_been_made.once
    end

    it 'adds default web hook headers to the request' do
      jenkins_integration.execute(push_sample_data)

      expect(
        a_request(:post, jenkins_hook_url)
          .with(headers: { 'X-Gitlab-Event' => 'Push Hook', 'Authorization' => jenkins_authorization })
      ).to have_been_made.once
    end

    it 'request url contains properly serialized username and password' do
      jenkins_integration.execute(push_sample_data)

      expect(
        a_request(:post, 'http://jenkins.example.com/project/my_project')
          .with(headers: { 'Authorization' => jenkins_authorization })
      ).to have_been_made.once
    end
  end
end
