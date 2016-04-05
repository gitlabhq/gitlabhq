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

describe TeamcityService, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project) }

    context "when a password was previously set" do
      before do
        @teamcity_service = TeamcityService.create(
          project: create(:project),
          properties: {
            teamcity_url: 'http://gitlab.com',
            username: 'mic',
            password: "password"
          }
        )
      end

      it "reset password if url changed" do
        @teamcity_service.teamcity_url = 'http://gitlab1.com'
        @teamcity_service.save
        expect(@teamcity_service.password).to be_nil
      end

      it "does not reset password if username changed" do
        @teamcity_service.username = "some_name"
        @teamcity_service.save
        expect(@teamcity_service.password).to eq("password")
      end

      it "does not reset password if new url is set together with password, even if it's the same password" do
        @teamcity_service.teamcity_url = 'http://gitlab_edited.com'
        @teamcity_service.password = 'password'
        @teamcity_service.save
        expect(@teamcity_service.password).to eq("password")
        expect(@teamcity_service.teamcity_url).to eq("http://gitlab_edited.com")
      end

      it "should reset password if url changed, even if setter called multiple times" do
        @teamcity_service.teamcity_url = 'http://gitlab1.com'
        @teamcity_service.teamcity_url = 'http://gitlab1.com'
        @teamcity_service.save
        expect(@teamcity_service.password).to be_nil
      end
    end

    context "when no password was previously set" do
      before do
        @teamcity_service = TeamcityService.create(
          project: create(:project),
          properties: {
            teamcity_url: 'http://gitlab.com',
            username: 'mic'
          }
        )
      end

      it "saves password if new url is set together with password" do
        @teamcity_service.teamcity_url = 'http://gitlab_edited.com'
        @teamcity_service.password = 'password'
        @teamcity_service.save
        expect(@teamcity_service.password).to eq("password")
        expect(@teamcity_service.teamcity_url).to eq("http://gitlab_edited.com")
      end
    end
  end

  module TeamcityServiceSpec
    Response = Struct.new(:code, :data) do
      def [](key)
        data[key]
      end
    end
  end

  describe '#build_info' do
    let(:teamcity_url) { 'http://gitlab.com' }
    let(:response) { TeamcityServiceSpec::Response.new(200, {}) }
    subject do
      TeamcityService.create(
        project: create(:project),
        properties: {
          teamcity_url: teamcity_url,
          username: 'mic',
          password: 'password',
          build_type: 'foo'
        })
    end
    before { allow(HTTParty).to receive(:get).and_return(response) }

    context 'when teamcity_url has no trailing slash' do
      it { expect(subject.build_info('123')).to eq(response) }
    end

    context 'when teamcity_url has a trailing slash' do
      let(:teamcity_url) { 'http://gitlab.com/' }

      it { expect(subject.build_info('123')).to eq(response) }
    end
  end

  describe '#build_page' do
    let(:teamcity_url) { 'http://gitlab.com' }
    let(:response_code) { 200 }
    let(:response) do
      TeamcityServiceSpec::Response.new(response_code, { 'build' => { 'id' => '666' } })
    end
    subject do
      TeamcityService.create(
        project: create(:project),
        properties: {
          teamcity_url: teamcity_url,
          username: 'mic',
          password: 'password',
          build_type: 'foo'
        })
    end
    before { allow(HTTParty).to receive(:get).and_return(response) }

    context 'when teamcity_url has no trailing slash' do
      it { expect(subject.build_page('123', 'unused')).to eq('http://gitlab.com/viewLog.html?buildId=666&buildTypeId=foo') }
    end

    context 'when teamcity_url has a trailing slash' do
      let(:teamcity_url) { 'http://gitlab.com/' }

      it { expect(subject.build_page('123', 'unused')).to eq('http://gitlab.com/viewLog.html?buildId=666&buildTypeId=foo') }
    end

    context 'when response code is not 200' do
      let(:response_code) { 500 }

      it { expect(subject.build_page('123', 'unused')).to eq('http://gitlab.com/viewLog.html?buildTypeId=foo') }
    end
  end

  describe '#commit_status' do
    let(:teamcity_url) { 'http://gitlab.com' }
    let(:response_code) { 200 }
    let(:build_status) { 'YAY SUCCESS!' }
    let(:response) do
      TeamcityServiceSpec::Response.new(response_code, {
        'build' => {
          'status' => build_status,
          'id' => '666'
        }
      })
    end
    subject do
      TeamcityService.create(
        project: create(:project),
        properties: {
          teamcity_url: teamcity_url,
          username: 'mic',
          password: 'password',
          build_type: 'foo'
        })
    end
    before { allow(HTTParty).to receive(:get).and_return(response) }

    context 'when response code is not 200' do
      let(:response_code) { 500 }

      it { expect(subject.commit_status('123', 'unused')).to eq(:error) }
    end

    context 'when response code is 404' do
      let(:response_code) { 404 }

      it { expect(subject.commit_status('123', 'unused')).to eq(:pending) }
    end

    context 'when response code is 200' do
      context 'when build status contains SUCCESS' do
        it { expect(subject.commit_status('123', 'unused')).to eq(:success) }
      end

      context 'when build status contains FAILURE' do
        let(:build_status) { 'NO FAILURE!' }

        it { expect(subject.commit_status('123', 'unused')).to eq(:failed) }
      end

      context 'when build status contains Pending' do
        let(:build_status) { 'NO Pending!' }

        it { expect(subject.commit_status('123', 'unused')).to eq(:pending) }
      end

      context 'when build status contains anything else' do
        let(:build_status) { 'FOO BAR!' }

        it { expect(subject.commit_status('123', 'unused')).to eq(:error) }
      end
    end
  end
end
