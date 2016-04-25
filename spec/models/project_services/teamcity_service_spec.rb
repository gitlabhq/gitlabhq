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
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    describe '#teamcity_url' do
      it 'does not validate the presence of teamcity_url if service is not active' do
        teamcity_service = service
        teamcity_service.active = false

        expect(teamcity_service).not_to validate_presence_of(:teamcity_url)
      end

      it 'validates the presence of teamcity_url if service is active' do
        teamcity_service = service
        teamcity_service.active = true

        expect(teamcity_service).to validate_presence_of(:teamcity_url)
      end
    end

    describe '#build_type' do
      it 'does not validate the presence of build_type if service is not active' do
        teamcity_service = service
        teamcity_service.active = false

        expect(teamcity_service).not_to validate_presence_of(:build_type)
      end

      it 'validates the presence of build_type if service is active' do
        teamcity_service = service
        teamcity_service.active = true

        expect(teamcity_service).to validate_presence_of(:build_type)
      end
    end

    describe '#username' do
      it 'does not validate the presence of username if service is not active' do
        teamcity_service = service
        teamcity_service.active = false

        expect(teamcity_service).not_to validate_presence_of(:username)
      end

      it 'does not validate the presence of username if username is nil' do
        teamcity_service = service
        teamcity_service.active = true
        teamcity_service.password = nil

        expect(teamcity_service).not_to validate_presence_of(:username)
      end

      it 'validates the presence of username if service is active and username is present' do
        teamcity_service = service
        teamcity_service.active = true
        teamcity_service.password = 'secret'

        expect(teamcity_service).to validate_presence_of(:username)
      end
    end

    describe '#password' do
      it 'does not validate the presence of password if service is not active' do
        teamcity_service = service
        teamcity_service.active = false

        expect(teamcity_service).not_to validate_presence_of(:password)
      end

      it 'does not validate the presence of password if username is nil' do
        teamcity_service = service
        teamcity_service.active = true
        teamcity_service.username = nil

        expect(teamcity_service).not_to validate_presence_of(:password)
      end

      it 'validates the presence of password if service is active and username is present' do
        teamcity_service = service
        teamcity_service.active = true
        teamcity_service.username = 'john'

        expect(teamcity_service).to validate_presence_of(:password)
      end
    end
  end

  describe 'Callbacks' do
    describe 'before_update :reset_password' do
      context 'when a password was previously set' do
        it 'resets password if url changed' do
          teamcity_service = service

          teamcity_service.teamcity_url = 'http://gitlab1.com'
          teamcity_service.save

          expect(teamcity_service.password).to be_nil
        end

        it 'does not reset password if username changed' do
          teamcity_service = service

          teamcity_service.username = 'some_name'
          teamcity_service.save

          expect(teamcity_service.password).to eq('password')
        end

        it "does not reset password if new url is set together with password, even if it's the same password" do
          teamcity_service = service

          teamcity_service.teamcity_url = 'http://gitlab_edited.com'
          teamcity_service.password = 'password'
          teamcity_service.save

          expect(teamcity_service.password).to eq('password')
          expect(teamcity_service.teamcity_url).to eq('http://gitlab_edited.com')
        end
      end

      it 'saves password if new url is set together with password when no password was previously set' do
        teamcity_service = service
        teamcity_service.password = nil

        teamcity_service.teamcity_url = 'http://gitlab_edited.com'
        teamcity_service.password = 'password'
        teamcity_service.save

        expect(teamcity_service.password).to eq('password')
        expect(teamcity_service.teamcity_url).to eq('http://gitlab_edited.com')
      end
    end
  end

  describe '#build_page' do
    it 'returns a specific URL when status is 500' do
      stub_request(status: 500)

      expect(service.build_page('123', 'unused')).to eq('http://gitlab.com/viewLog.html?buildTypeId=foo')
    end

    it 'returns a build URL when teamcity_url has no trailing slash' do
      stub_request(body: %Q({"build":{"id":"666"}}))

      expect(service(teamcity_url: 'http://gitlab.com').build_page('123', 'unused')).to eq('http://gitlab.com/viewLog.html?buildId=666&buildTypeId=foo')
    end
  end

  describe '#commit_status' do
    it 'sets commit status to :error when status is 500' do
      stub_request(status: 500)

      expect(service.commit_status('123', 'unused')).to eq(:error)
    end

    it 'sets commit status to "pending" when status is 404' do
      stub_request(status: 404)

      expect(service.commit_status('123', 'unused')).to eq('pending')
    end

    it 'sets commit status to "success" when build status contains SUCCESS' do
      stub_request(build_status: 'YAY SUCCESS!')

      expect(service.commit_status('123', 'unused')).to eq('success')
    end

    it 'sets commit status to "failed" when build status contains FAILURE' do
      stub_request(build_status: 'NO FAILURE!')

      expect(service.commit_status('123', 'unused')).to eq('failed')
    end

    it 'sets commit status to "pending" when build status contains Pending' do
      stub_request(build_status: 'NO Pending!')

      expect(service.commit_status('123', 'unused')).to eq('pending')
    end

    it 'sets commit status to :error when build status is unknown' do
      stub_request(build_status: 'FOO BAR!')

      expect(service.commit_status('123', 'unused')).to eq(:error)
    end
  end

  def service(teamcity_url: 'http://gitlab.com')
    described_class.create(
      project: build_stubbed(:empty_project),
      properties: {
        teamcity_url: teamcity_url,
        username: 'mic',
        password: 'password',
        build_type: 'foo'
      }
    )
  end

  def stub_request(status: 200, body: nil, build_status: 'success')
    teamcity_full_url = 'http://mic:password@gitlab.com/httpAuth/app/rest/builds/branch:unspecified:any,number:123'
    body ||= %Q({"build":{"status":"#{build_status}","id":"666"}})

    WebMock.stub_request(:get, teamcity_full_url).to_return(
      status: status,
      headers: { 'Content-Type' => 'application/json' },
      body: body
    )
  end
end
