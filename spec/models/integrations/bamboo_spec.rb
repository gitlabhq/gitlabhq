# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Bamboo, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers
  include StubRequests

  let(:bamboo_url) { 'http://gitlab.com/bamboo' }

  let_it_be(:project) { create(:project) }

  subject(:integration) do
    described_class.create!(
      project: project,
      properties: {
        bamboo_url: bamboo_url,
        username: 'mic',
        password: 'password',
        build_key: 'foo'
      }
    )
  end

  describe 'Validations' do
    context 'when active' do
      before do
        integration.active = true
      end

      it { is_expected.to validate_presence_of(:build_key) }
      it { is_expected.to validate_presence_of(:bamboo_url) }
      it_behaves_like 'issue tracker integration URL attribute', :bamboo_url

      describe '#username' do
        it 'does not validate the presence of username if password is nil' do
          integration.password = nil

          expect(integration).not_to validate_presence_of(:username)
        end

        it 'validates the presence of username if password is present' do
          integration.password = 'secret'

          expect(integration).to validate_presence_of(:username)
        end
      end

      describe '#password' do
        it 'does not validate the presence of password if username is nil' do
          integration.username = nil

          expect(integration).not_to validate_presence_of(:password)
        end

        it 'validates the presence of password if username is present' do
          integration.username = 'john'

          expect(integration).to validate_presence_of(:password)
        end
      end
    end

    context 'when inactive' do
      before do
        integration.active = false
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
          integration.bamboo_url = 'http://gitlab1.com'
          integration.save!

          expect(integration.password).to be_nil
        end

        it 'does not reset password if username changed' do
          integration.username = 'some_name'
          integration.save!

          expect(integration.password).to eq('password')
        end

        it "does not reset password if new url is set together with password, even if it's the same password" do
          integration.bamboo_url = 'http://gitlab_edited.com'
          integration.password = 'password'
          integration.save!

          expect(integration.password).to eq('password')
          expect(integration.bamboo_url).to eq('http://gitlab_edited.com')
        end
      end

      it 'saves password if new url is set together with password when no password was previously set' do
        integration.password = nil

        integration.bamboo_url = 'http://gitlab_edited.com'
        integration.password = 'password'
        integration.save!

        expect(integration.password).to eq('password')
        expect(integration.bamboo_url).to eq('http://gitlab_edited.com')
      end
    end
  end

  describe '#execute' do
    it 'runs update and build action' do
      stub_update_and_build_request

      integration.execute(Gitlab::DataBuilder::Push::SAMPLE_DATA)
    end
  end

  describe '#build_page' do
    it 'returns the contents of the reactive cache' do
      stub_reactive_cache(integration, { build_page: 'foo' }, 'sha', 'ref')

      expect(integration.build_page('sha', 'ref')).to eq('foo')
    end
  end

  describe '#commit_status' do
    it 'returns the contents of the reactive cache' do
      stub_reactive_cache(integration, { commit_status: 'foo' }, 'sha', 'ref')

      expect(integration.commit_status('sha', 'ref')).to eq('foo')
    end
  end

  shared_examples 'reactive cache calculation' do
    describe '#build_page' do
      subject { integration.calculate_reactive_cache('123', 'unused')[:build_page] }

      it 'returns a specific URL when status is 500' do
        stub_request(status: 500)

        is_expected.to eq('http://gitlab.com/bamboo/browse/foo')
      end

      it 'returns a specific URL when response has no results' do
        stub_request(body: %q({"results":{"results":{"size":"0"}}}))

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

    describe '#commit_status' do
      subject { integration.calculate_reactive_cache('123', 'unused')[:commit_status] }

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

      Gitlab::HTTP::HTTP_ERRORS.each do |http_error|
        it "sets commit status to :error with a #{http_error.name} error" do
          WebMock.stub_request(:get, 'http://gitlab.com/bamboo/rest/api/latest/result/byChangeset/123?os_authType=basic')
            .to_raise(http_error)

          expect(Gitlab::ErrorTracking)
            .to receive(:log_exception)
            .with(instance_of(http_error), project_id: project.id)

          is_expected.to eq(:error)
        end
      end
    end
  end

  describe '#calculate_reactive_cache' do
    context 'when Bamboo API returns single result' do
      let(:bamboo_response_template) do
        %q({"results":{"results":{"size":"1","result":{"buildState":"%{build_state}","planResultKey":{"key":"42"}}}}})
      end

      it_behaves_like 'reactive cache calculation'
    end

    context 'when Bamboo API returns an array of results and we only consider the last one' do
      let(:bamboo_response_template) do
        %q({"results":{"results":{"size":"2","result":[{"buildState":"%{build_state}","planResultKey":{"key":"41"}},{"buildState":"%{build_state}","planResultKey":{"key":"42"}}]}}})
      end

      it_behaves_like 'reactive cache calculation'
    end
  end

  def stub_update_and_build_request(status: 200, body: nil)
    bamboo_full_url = 'http://gitlab.com/bamboo/updateAndBuild.action?buildKey=foo&os_authType=basic'

    stub_bamboo_request(bamboo_full_url, status, body)
  end

  def stub_request(status: 200, body: nil)
    bamboo_full_url = 'http://gitlab.com/bamboo/rest/api/latest/result/byChangeset/123?os_authType=basic'

    stub_bamboo_request(bamboo_full_url, status, body)
  end

  def stub_bamboo_request(url, status, body)
    stub_full_request(url).to_return(
      status: status,
      headers: { 'Content-Type' => 'application/json' },
      body: body
    ).with(basic_auth: %w(mic password))
  end

  def bamboo_response(build_state: 'success')
    # reference: https://docs.atlassian.com/atlassian-bamboo/REST/6.2.5/#d2e786
    bamboo_response_template % { build_state: build_state }
  end
end
