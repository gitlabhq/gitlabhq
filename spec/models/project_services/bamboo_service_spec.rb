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
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    describe '#bamboo_url' do
      it 'does not validate the presence of bamboo_url if service is not active' do
        bamboo_service = service
        bamboo_service.active = false

        expect(bamboo_service).not_to validate_presence_of(:bamboo_url)
      end

      it 'validates the presence of bamboo_url if service is active' do
        bamboo_service = service
        bamboo_service.active = true

        expect(bamboo_service).to validate_presence_of(:bamboo_url)
      end
    end

    describe '#build_key' do
      it 'does not validate the presence of build_key if service is not active' do
        bamboo_service = service
        bamboo_service.active = false

        expect(bamboo_service).not_to validate_presence_of(:build_key)
      end

      it 'validates the presence of build_key if service is active' do
        bamboo_service = service
        bamboo_service.active = true

        expect(bamboo_service).to validate_presence_of(:build_key)
      end
    end

    describe '#username' do
      it 'does not validate the presence of username if service is not active' do
        bamboo_service = service
        bamboo_service.active = false

        expect(bamboo_service).not_to validate_presence_of(:username)
      end

      it 'does not validate the presence of username if username is nil' do
        bamboo_service = service
        bamboo_service.active = true
        bamboo_service.password = nil

        expect(bamboo_service).not_to validate_presence_of(:username)
      end

      it 'validates the presence of username if service is active and username is present' do
        bamboo_service = service
        bamboo_service.active = true
        bamboo_service.password = 'secret'

        expect(bamboo_service).to validate_presence_of(:username)
      end
    end

    describe '#password' do
      it 'does not validate the presence of password if service is not active' do
        bamboo_service = service
        bamboo_service.active = false

        expect(bamboo_service).not_to validate_presence_of(:password)
      end

      it 'does not validate the presence of password if username is nil' do
        bamboo_service = service
        bamboo_service.active = true
        bamboo_service.username = nil

        expect(bamboo_service).not_to validate_presence_of(:password)
      end

      it 'validates the presence of password if service is active and username is present' do
        bamboo_service = service
        bamboo_service.active = true
        bamboo_service.username = 'john'

        expect(bamboo_service).to validate_presence_of(:password)
      end
    end
  end

  describe 'Callbacks' do
    describe 'before_update :reset_password' do
      context 'when a password was previously set' do
        it 'resets password if url changed' do
          bamboo_service = service

          bamboo_service.bamboo_url = 'http://gitlab1.com'
          bamboo_service.save

          expect(bamboo_service.password).to be_nil
        end

        it 'does not reset password if username changed' do
          bamboo_service = service

          bamboo_service.username = 'some_name'
          bamboo_service.save

          expect(bamboo_service.password).to eq('password')
        end

        it "does not reset password if new url is set together with password, even if it's the same password" do
          bamboo_service = service

          bamboo_service.bamboo_url = 'http://gitlab_edited.com'
          bamboo_service.password = 'password'
          bamboo_service.save

          expect(bamboo_service.password).to eq('password')
          expect(bamboo_service.bamboo_url).to eq('http://gitlab_edited.com')
        end
      end

      it 'saves password if new url is set together with password when no password was previously set' do
        bamboo_service = service
        bamboo_service.password = nil

        bamboo_service.bamboo_url = 'http://gitlab_edited.com'
        bamboo_service.password = 'password'
        bamboo_service.save

        expect(bamboo_service.password).to eq('password')
        expect(bamboo_service.bamboo_url).to eq('http://gitlab_edited.com')
      end
    end
  end

  describe '#build_page' do
    it 'returns a specific URL when status is 500' do
      stub_request(status: 500)

      expect(service.build_page('123', 'unused')).to eq('http://gitlab.com/browse/foo')
    end

    it 'returns a specific URL when response has no results' do
      stub_request(body: %Q({"results":{"results":{"size":"0"}}}))

      expect(service.build_page('123', 'unused')).to eq('http://gitlab.com/browse/foo')
    end

    it 'returns a build URL when bamboo_url has no trailing slash' do
      stub_request(body: %Q({"results":{"results":{"result":{"planResultKey":{"key":"42"}}}}}))

      expect(service(bamboo_url: 'http://gitlab.com').build_page('123', 'unused')).to eq('http://gitlab.com/browse/42')
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

    it 'sets commit status to "pending" when response has no results' do
      stub_request(body: %Q({"results":{"results":{"size":"0"}}}))

      expect(service.commit_status('123', 'unused')).to eq('pending')
    end

    it 'sets commit status to "success" when build state contains Success' do
      stub_request(build_state: 'YAY Success!')

      expect(service.commit_status('123', 'unused')).to eq('success')
    end

    it 'sets commit status to "failed" when build state contains Failed' do
      stub_request(build_state: 'NO Failed!')

      expect(service.commit_status('123', 'unused')).to eq('failed')
    end

    it 'sets commit status to "pending" when build state contains Pending' do
      stub_request(build_state: 'NO Pending!')

      expect(service.commit_status('123', 'unused')).to eq('pending')
    end

    it 'sets commit status to :error when build state is unknown' do
      stub_request(build_state: 'FOO BAR!')

      expect(service.commit_status('123', 'unused')).to eq(:error)
    end
  end

  def service(bamboo_url: 'http://gitlab.com')
    described_class.create(
      project: build_stubbed(:empty_project),
      properties: {
        bamboo_url: bamboo_url,
        username: 'mic',
        password: 'password',
        build_key: 'foo'
      }
    )
  end

  def stub_request(status: 200, body: nil, build_state: 'success')
    bamboo_full_url = 'http://mic:password@gitlab.com/rest/api/latest/result?label=123&os_authType=basic'
    body ||= %Q({"results":{"results":{"result":{"buildState":"#{build_state}"}}}})

    WebMock.stub_request(:get, bamboo_full_url).to_return(
      status: status,
      headers: { 'Content-Type' => 'application/json' },
      body: body
    )
  end
end
