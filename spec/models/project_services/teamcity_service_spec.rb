require 'spec_helper'

describe TeamcityService, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers

  let(:teamcity_url) { 'http://gitlab.com/teamcity' }

  subject(:service) do
    described_class.create(
      project: create(:project),
      properties: {
        teamcity_url: teamcity_url,
        username: 'mic',
        password: 'password',
        build_type: 'foo'
      }
    )
  end

  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

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
      before do
        subject.active = false
      end

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
    it 'returns the contents of the reactive cache' do
      stub_reactive_cache(service, { build_page: 'foo' }, 'sha', 'ref')

      expect(service.build_page('sha', 'ref')).to eq('foo')
    end
  end

  describe '#commit_status' do
    it 'returns the contents of the reactive cache' do
      stub_reactive_cache(service, { commit_status: 'foo' }, 'sha', 'ref')

      expect(service.commit_status('sha', 'ref')).to eq('foo')
    end
  end

  describe '#calculate_reactive_cache' do
    context 'build_page' do
      subject { service.calculate_reactive_cache('123', 'unused')[:build_page] }

      it 'returns a specific URL when status is 500' do
        stub_request(status: 500)

        is_expected.to eq('http://gitlab.com/teamcity/viewLog.html?buildTypeId=foo')
      end

      it 'returns a build URL when teamcity_url has no trailing slash' do
        stub_request(body: %q({"build":{"id":"666"}}))

        is_expected.to eq('http://gitlab.com/teamcity/viewLog.html?buildId=666&buildTypeId=foo')
      end

      context 'teamcity_url has trailing slash' do
        let(:teamcity_url) { 'http://gitlab.com/teamcity/' }

        it 'returns a build URL' do
          stub_request(body: %q({"build":{"id":"666"}}))

          is_expected.to eq('http://gitlab.com/teamcity/viewLog.html?buildId=666&buildTypeId=foo')
        end
      end
    end

    context 'commit_status' do
      subject { service.calculate_reactive_cache('123', 'unused')[:commit_status] }

      it 'sets commit status to :error when status is 500' do
        stub_request(status: 500)

        is_expected.to eq(:error)
      end

      it 'sets commit status to "pending" when status is 404' do
        stub_request(status: 404)

        is_expected.to eq('pending')
      end

      it 'sets commit status to "success" when build status contains SUCCESS' do
        stub_request(build_status: 'YAY SUCCESS!')

        is_expected.to eq('success')
      end

      it 'sets commit status to "failed" when build status contains FAILURE' do
        stub_request(build_status: 'NO FAILURE!')

        is_expected.to eq('failed')
      end

      it 'sets commit status to "pending" when build status contains Pending' do
        stub_request(build_status: 'NO Pending!')

        is_expected.to eq('pending')
      end

      it 'sets commit status to :error when build status is unknown' do
        stub_request(build_status: 'FOO BAR!')

        is_expected.to eq(:error)
      end
    end
  end

  def stub_request(status: 200, body: nil, build_status: 'success')
    teamcity_full_url = 'http://gitlab.com/teamcity/httpAuth/app/rest/builds/branch:unspecified:any,number:123'
    auth = %w(mic password)

    body ||= %Q({"build":{"status":"#{build_status}","id":"666"}})

    WebMock.stub_request(:get, teamcity_full_url).with(basic_auth: auth).to_return(
      status: status,
      headers: { 'Content-Type' => 'application/json' },
      body: body
    )
  end
end
