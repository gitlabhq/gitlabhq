require 'spec_helper'

describe BambooService, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers

  let(:bamboo_url) { 'http://gitlab.com/bamboo' }

  subject(:service) do
    described_class.create(
      project: create(:project),
      properties: {
        bamboo_url: bamboo_url,
        username: 'mic',
        password: 'password',
        build_key: 'foo'
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

      it { is_expected.to validate_presence_of(:build_key) }
      it { is_expected.to validate_presence_of(:bamboo_url) }
      it_behaves_like 'issue tracker service URL attribute', :bamboo_url

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

      it { is_expected.not_to validate_presence_of(:build_key) }
      it { is_expected.not_to validate_presence_of(:bamboo_url) }
      it { is_expected.not_to validate_presence_of(:username) }
      it { is_expected.not_to validate_presence_of(:password) }
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
    context '#build_page' do
      subject { service.calculate_reactive_cache('123', 'unused')[:build_page] }

      it 'returns a specific URL when status is 500' do
        stub_request(status: 500)

        is_expected.to eq('http://gitlab.com/bamboo/browse/foo')
      end

      it 'returns a specific URL when response has no results' do
        stub_request(body: bamboo_response(size: 0))

        is_expected.to eq('http://gitlab.com/bamboo/browse/foo')
      end

      it 'returns a build URL when bamboo_url has no trailing slash' do
        stub_request(body: bamboo_response)

        is_expected.to eq('http://gitlab.com/bamboo/browse/42')
      end

      context 'bamboo_url has trailing slash' do
        let(:bamboo_url) { 'http://gitlab.com/bamboo/' }

        it 'returns a build URL' do
          stub_request(body: bamboo_response)

          is_expected.to eq('http://gitlab.com/bamboo/browse/42')
        end
      end
    end

    context '#commit_status' do
      subject { service.calculate_reactive_cache('123', 'unused')[:commit_status] }

      it 'sets commit status to :error when status is 500' do
        stub_request(status: 500)

        is_expected.to eq(:error)
      end

      it 'sets commit status to "pending" when status is 404' do
        stub_request(status: 404)

        is_expected.to eq('pending')
      end

      it 'sets commit status to "pending" when response has no results' do
        stub_request(body: %q({"results":{"results":{"size":"0"}}}))

        is_expected.to eq('pending')
      end

      it 'sets commit status to "success" when build state contains Success' do
        stub_request(body: bamboo_response(build_state: 'YAY Success!'))

        is_expected.to eq('success')
      end

      it 'sets commit status to "failed" when build state contains Failed' do
        stub_request(body: bamboo_response(build_state: 'NO Failed!'))

        is_expected.to eq('failed')
      end

      it 'sets commit status to "pending" when build state contains Pending' do
        stub_request(body: bamboo_response(build_state: 'NO Pending!'))

        is_expected.to eq('pending')
      end

      it 'sets commit status to :error when build state is unknown' do
        stub_request(body: bamboo_response(build_state: 'FOO BAR!'))

        is_expected.to eq(:error)
      end
    end
  end

  def stub_request(status: 200, body: nil)
    bamboo_full_url = 'http://gitlab.com/bamboo/rest/api/latest/result?label=123&os_authType=basic'

    WebMock.stub_request(:get, bamboo_full_url).to_return(
      status: status,
      headers: { 'Content-Type' => 'application/json' },
      body: body
    ).with(basic_auth: %w(mic password))
  end

  def bamboo_response(result_key: 42, build_state: 'success', size: 1)
    %Q({"results":{"results":{"size":"#{size}","result":{"buildState":"#{build_state}","planResultKey":{"key":"#{result_key}"}}}}})
  end
end
