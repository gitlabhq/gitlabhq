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

describe BambooService, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project) }

    context "when a password was previously set" do
      before do
        @bamboo_service = BambooService.create(
          project: create(:project),
          properties: {
            bamboo_url: 'http://gitlab.com',
            username: 'mic',
            password: "password"
          }
        )
      end

      it "reset password if url changed" do
        @bamboo_service.bamboo_url = 'http://gitlab1.com'
        @bamboo_service.save
        expect(@bamboo_service.password).to be_nil
      end

      it "does not reset password if username changed" do
        @bamboo_service.username = "some_name"
        @bamboo_service.save
        expect(@bamboo_service.password).to eq("password")
      end

      it "does not reset password if new url is set together with password, even if it's the same password" do
        @bamboo_service.bamboo_url = 'http://gitlab_edited.com'
        @bamboo_service.password = 'password'
        @bamboo_service.save
        expect(@bamboo_service.password).to eq("password")
        expect(@bamboo_service.bamboo_url).to eq("http://gitlab_edited.com")
      end

      it "should reset password if url changed, even if setter called multiple times" do
        @bamboo_service.bamboo_url = 'http://gitlab1.com'
        @bamboo_service.bamboo_url = 'http://gitlab1.com'
        @bamboo_service.save
        expect(@bamboo_service.password).to be_nil
      end
    end

    context "when no password was previously set" do
      before do
        @bamboo_service = BambooService.create(
          project: create(:project),
          properties: {
            bamboo_url: 'http://gitlab.com',
            username: 'mic'
          }
        )
      end

      it "saves password if new url is set together with password" do
        @bamboo_service.bamboo_url = 'http://gitlab_edited.com'
        @bamboo_service.password = 'password'
        @bamboo_service.save
        expect(@bamboo_service.password).to eq("password")
        expect(@bamboo_service.bamboo_url).to eq("http://gitlab_edited.com")
      end
    end
  end

  describe '#build_page' do
    let(:bamboo_full_url) { 'http://mic:password@gitlab.com/rest/api/latest/result?label=123&os_authType=basic' }

    context 'when response code is not 200' do
      before do
        WebMock.stub_request(:get, bamboo_full_url).to_return(status: 500)
      end
      subject do
        BambooService.create(
          project: build_stubbed(:empty_project),
          properties: {
            bamboo_url: 'http://gitlab.com',
            username: 'mic',
            password: 'password',
            build_key: 'foo'
          }
        )
      end

      it { expect(subject.build_page('123', 'unused')).to eq('http://gitlab.com/browse/foo') }
    end

    context 'when response has no result' do
      before do
        WebMock.stub_request(:get, bamboo_full_url).to_return(
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: %Q({"results":{"results":{"size":"0"}}})
        )
      end
      subject do
        BambooService.create(
          project: build_stubbed(:empty_project),
          properties: {
            bamboo_url: 'http://gitlab.com',
            username: 'mic',
            password: 'password',
            build_key: 'foo'
          }
        )
      end

      it { expect(subject.build_page('123', 'unused')).to eq('http://gitlab.com/browse/foo') }
    end

    context 'when response has result' do
      before do
        WebMock.stub_request(:get, bamboo_full_url).to_return(
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: %Q({"results":{"results":{"result":{"planResultKey":{"key":"42"}}}}})
        )
      end
      subject do
        BambooService.create(
          project: build_stubbed(:empty_project),
          properties: {
            bamboo_url: bamboo_url,
            username: 'mic',
            password: 'password',
            build_key: 'foo'
          }
        )
      end

      context 'when bamboo_url has no trailing slash' do
        let(:bamboo_url) { 'http://gitlab.com' }

        it { expect(subject.build_page('123', 'unused')).to eq('http://gitlab.com/browse/42') }
      end

      context 'when bamboo_url has a trailing slash' do
        let(:bamboo_url) { 'http://gitlab.com/' }

        it { expect(subject.build_page('123', 'unused')).to eq('http://gitlab.com/browse/42') }
      end
    end
  end

  describe '#commit_status' do
    let(:bamboo_full_url) { 'http://mic:password@gitlab.com/rest/api/latest/result?label=123&os_authType=basic' }
    subject do
      BambooService.create(
        project: build_stubbed(:empty_project),
        properties: {
          bamboo_url: 'http://gitlab.com',
          username: 'mic',
          password: 'password'
        }
      )
    end

    context 'when response code is not 200' do
      before do
        WebMock.stub_request(:get, bamboo_full_url).to_return(status: 500)
      end

      it { expect(subject.commit_status('123', 'unused')).to eq(:error) }
    end

    context 'when response code is 404' do
      before do
        WebMock.stub_request(:get, bamboo_full_url).to_return(status: 404)
      end

      it { expect(subject.commit_status('123', 'unused')).to eq('pending') }
    end

    context 'when response has no results' do
      before do
        WebMock.stub_request(:get, bamboo_full_url).to_return(
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: %Q({"results":{"results":{"size":"0"}}})
        )
      end

      it { expect(subject.commit_status('123', 'unused')).to eq('pending') }
    end

    context 'when response has results' do
      let(:build_state) { 'YAY Success!' }
      before do
        WebMock.stub_request(:get, bamboo_full_url).to_return(
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: %Q({"results":{"results":{"result":{"buildState":"#{build_state}"}}}})
        )
      end

      context 'when build status contains Success' do
        it { expect(subject.commit_status('123', 'unused')).to eq('success') }
      end

      context 'when build status contains Failed' do
        let(:build_state) { 'NO Failed!' }

        it { expect(subject.commit_status('123', 'unused')).to eq('failed') }
      end

      context 'when build status contains Failed' do
        let(:build_state) { 'NO Pending!' }

        it { expect(subject.commit_status('123', 'unused')).to eq('pending') }
      end

      context 'when build status contains anything else' do
        let(:build_state) { 'FOO BAR!' }

        it { expect(subject.commit_status('123', 'unused')).to eq(:error) }
      end
    end
  end
end
