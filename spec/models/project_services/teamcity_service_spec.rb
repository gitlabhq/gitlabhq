require 'spec_helper'

describe TeamcityService, models: true do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    subject { service }

    context 'when service is active' do
      before { subject.active = true }

      it { is_expected.to validate_presence_of(:build_type) }
      it { is_expected.to validate_presence_of(:teamcity_url) }
      it_behaves_like 'issue tracker service URL attribute', :teamcity_url

      describe '#username' do
        it 'does not validate the presence of username if password is nil' do
          subject.password = nil

          expect(subject).not_to validate_presence_of(:username)
        end

        it 'validates the presence of username if password is present' do
          subject.password = 'secret'

          expect(subject).to validate_presence_of(:username)
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

    context 'when service is inactive' do
      before { subject.active = false }

      it { is_expected.not_to validate_presence_of(:build_type) }
      it { is_expected.not_to validate_presence_of(:teamcity_url) }
      it { is_expected.not_to validate_presence_of(:username) }
      it { is_expected.not_to validate_presence_of(:password) }
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

      expect(service.build_page('123', 'unused')).to eq('http://gitlab.com/teamcity/viewLog.html?buildTypeId=foo')
    end

    it 'returns a build URL when teamcity_url has no trailing slash' do
      stub_request(body: %Q({"build":{"id":"666"}}))

      expect(service(teamcity_url: 'http://gitlab.com/teamcity').build_page('123', 'unused')).to eq('http://gitlab.com/teamcity/viewLog.html?buildId=666&buildTypeId=foo')
    end

    it 'returns a build URL when teamcity_url has a trailing slash' do
      stub_request(body: %Q({"build":{"id":"666"}}))

      expect(service(teamcity_url: 'http://gitlab.com/teamcity/').build_page('123', 'unused')).to eq('http://gitlab.com/teamcity/viewLog.html?buildId=666&buildTypeId=foo')
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

  def service(teamcity_url: 'http://gitlab.com/teamcity')
    described_class.create(
      project: create(:empty_project),
      properties: {
        teamcity_url: teamcity_url,
        username: 'mic',
        password: 'password',
        build_type: 'foo'
      }
    )
  end

  def stub_request(status: 200, body: nil, build_status: 'success')
    teamcity_full_url = 'http://mic:password@gitlab.com/teamcity/httpAuth/app/rest/builds/branch:unspecified:any,number:123'
    body ||= %Q({"build":{"status":"#{build_status}","id":"666"}})

    WebMock.stub_request(:get, teamcity_full_url).to_return(
      status: status,
      headers: { 'Content-Type' => 'application/json' },
      body: body
    )
  end
end
