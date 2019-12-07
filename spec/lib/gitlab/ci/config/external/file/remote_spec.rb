# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::External::File::Remote do
  include StubRequests

  let(:context_params) { { sha: '12345' } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }
  let(:params) { { remote: location } }
  let(:remote_file) { described_class.new(params, context) }
  let(:location) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
  let(:remote_file_content) do
    <<~HEREDOC
      before_script:
        - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
        - ruby -v
        - which ruby
        - bundle install --jobs $(nproc)  "${FLAGS[@]}"
    HEREDOC
  end

  before do
    allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
      allow(instance).to receive(:check_execution_time!)
    end
  end

  describe '#matching?' do
    context 'when a remote is specified' do
      let(:params) { { remote: 'http://remote' } }

      it 'returns true' do
        expect(remote_file).to be_matching
      end
    end

    context 'with a missing remote' do
      let(:params) { { remote: nil } }

      it 'returns false' do
        expect(remote_file).not_to be_matching
      end
    end

    context 'with a missing remote key' do
      let(:params) { {} }

      it 'returns false' do
        expect(remote_file).not_to be_matching
      end
    end
  end

  describe "#valid?" do
    context 'when is a valid remote url' do
      before do
        stub_full_request(location).to_return(body: remote_file_content)
      end

      it 'returns true' do
        expect(remote_file.valid?).to be_truthy
      end
    end

    context 'with an irregular url' do
      let(:location) { 'not-valid://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }

      it 'returns false' do
        expect(remote_file.valid?).to be_falsy
      end
    end

    context 'with a timeout' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_raise(Timeout::Error)
      end

      it 'is falsy' do
        expect(remote_file.valid?).to be_falsy
      end
    end

    context 'when is not a yaml file' do
      let(:location) { 'https://asdasdasdaj48ggerexample.com' }

      it 'is falsy' do
        expect(remote_file.valid?).to be_falsy
      end
    end

    context 'with an internal url' do
      let(:location) { 'http://localhost:8080' }

      it 'is falsy' do
        expect(remote_file.valid?).to be_falsy
      end
    end
  end

  describe "#content" do
    context 'with a valid remote file' do
      before do
        stub_full_request(location).to_return(body: remote_file_content)
      end

      it 'returns the content of the file' do
        expect(remote_file.content).to eql(remote_file_content)
      end
    end

    context 'with a timeout' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_raise(Timeout::Error)
      end

      it 'is falsy' do
        expect(remote_file.content).to be_falsy
      end
    end

    context 'with an invalid remote url' do
      let(:location) { 'https://asdasdasdaj48ggerexample.com' }

      before do
        stub_full_request(location).to_raise(SocketError.new('Some HTTP error'))
      end

      it 'is nil' do
        expect(remote_file.content).to be_nil
      end
    end

    context 'with an internal url' do
      let(:location) { 'http://localhost:8080' }

      it 'is nil' do
        expect(remote_file.content).to be_nil
      end
    end
  end

  describe "#error_message" do
    subject { remote_file.error_message }

    context 'when remote file location is not valid' do
      let(:location) { 'not-valid://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }

      it 'returns an error message describing invalid address' do
        expect(subject).to match /does not have a valid address!/
      end
    end

    context 'when timeout error has been raised' do
      before do
        stub_full_request(location).to_timeout
      end

      it 'returns error message about a timeout' do
        expect(subject).to match /could not be fetched because of a timeout error!/
      end
    end

    context 'when HTTP error has been raised' do
      before do
        stub_full_request(location).to_raise(Gitlab::HTTP::Error)
      end

      it 'returns error message about a HTTP error' do
        expect(subject).to match /could not be fetched because of HTTP error!/
      end
    end

    context 'when response has 404 status' do
      before do
        stub_full_request(location).to_return(body: remote_file_content, status: 404)
      end

      it 'returns error message about a timeout' do
        expect(subject).to match /could not be fetched because of HTTP code `404` error!/
      end
    end

    context 'when the URL is blocked' do
      let(:location) { 'http://127.0.0.1/some/path/to/config.yaml' }

      it 'includes details about blocked URL' do
        expect(subject).to eq "Remote file could not be fetched because URL '#{location}' " \
                              'is blocked: Requests to localhost are not allowed!'
      end
    end
  end

  describe '#expand_context' do
    let(:params) { { remote: 'http://remote' } }

    subject { remote_file.send(:expand_context_attrs) }

    it 'drops all parameters' do
      is_expected.to be_empty
    end
  end
end
