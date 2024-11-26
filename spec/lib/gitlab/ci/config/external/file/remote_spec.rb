# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Remote, feature_category: :pipeline_composition do
  include StubRequests

  let(:variables) { Gitlab::Ci::Variables::Collection.new([{ 'key' => 'GITLAB_TOKEN', 'value' => 'secret_file', 'masked' => true }]) }
  let(:context_params) { { sha: '12345', variables: variables } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }
  let(:params) { { remote: location } }
  let(:remote_file) { described_class.new(params, context) }
  let(:location) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.secret_file.yml' }
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
    subject(:valid?) do
      Gitlab::Ci::Config::External::Mapper::Verifier.new(context).process([remote_file])
      remote_file.valid?
    end

    context 'when is a valid remote url' do
      before do
        stub_full_request(location).to_return(body: remote_file_content)
      end

      it { is_expected.to be_truthy }
    end

    context 'with an irregular url' do
      let(:location) { 'not-valid://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }

      it { is_expected.to be_falsy }
    end

    context 'with a timeout' do
      before do
        allow_next_instance_of(HTTParty::Request) do |instance|
          allow(instance).to receive(:perform).and_raise(Timeout::Error)
        end
      end

      it { is_expected.to be_falsy }
    end

    context 'when is not a yaml file' do
      let(:location) { 'https://asdasdasdaj48ggerexample.com' }

      it { is_expected.to be_falsy }
    end

    context 'with an internal url' do
      let(:location) { 'http://localhost:8080' }

      it { is_expected.to be_falsy }
    end
  end

  describe "#content" do
    subject(:content) do
      remote_file.preload_content
      remote_file.content
    end

    context 'with a valid remote file' do
      before do
        stub_full_request(location).to_return(body: remote_file_content)
      end

      it 'returns the content of the file' do
        expect(content).to eql(remote_file_content)
      end
    end

    context 'with a timeout' do
      before do
        allow_next_instance_of(HTTParty::Request) do |instance|
          allow(instance).to receive(:perform).and_raise(Timeout::Error)
        end
      end

      it 'is falsy' do
        expect(content).to be_falsy
      end
    end

    context 'with an invalid remote url' do
      let(:location) { 'https://asdasdasdaj48ggerexample.com' }

      before do
        stub_full_request(location).to_raise(SocketError.new('Some HTTP error'))
      end

      it 'is nil' do
        expect(content).to be_nil
      end
    end

    context 'with an internal url' do
      let(:location) { 'http://localhost:8080' }

      it 'is nil' do
        expect(content).to be_nil
      end
    end
  end

  describe '#preload_content' do
    context 'when the parallel request queue is full' do
      let(:location1) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.secret_file1.yml' }
      let(:location2) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.secret_file2.yml' }

      before do
        # Makes the parallel queue full easily
        stub_const("Gitlab::Ci::Config::External::Context::MAX_PARALLEL_REMOTE_REQUESTS", 1)

        # Adding a failing promise to the queue
        promise = Concurrent::Promise.new do
          sleep 1.1
          raise Timeout::Error
        end

        context.execute_remote_parallel_request(
          Gitlab::HTTP_V2::LazyResponse.new(promise, location1, {}, nil)
        )

        stub_full_request(location2).to_return(body: remote_file_content)
      end

      it 'waits for the queue' do
        file2 = described_class.new({ remote: location2 }, context)

        start_at = Time.current
        file2.preload_content
        end_at = Time.current

        expect(end_at - start_at).to be > 1
      end
    end
  end

  describe "#error_message" do
    subject(:error_message) do
      Gitlab::Ci::Config::External::Mapper::Verifier.new(context).process([remote_file])
      remote_file.error_message
    end

    context 'when remote file location is not valid' do
      let(:location) { 'not-valid://gitlab.com/gitlab-org/gitlab-foss/blob/1234/?secret_file.yml' }

      it 'returns an error message describing invalid address' do
        expect(subject).to eq('Remote file `not-valid://gitlab.com/gitlab-org/gitlab-foss/blob/1234/?[MASKED]xxx.yml` does not have a valid address!')
      end
    end

    context 'when timeout error has been raised' do
      before do
        stub_full_request(location).to_timeout
      end

      it 'returns error message about a timeout' do
        expect(subject).to eq('Remote file `https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.[MASKED]xxx.yml` could not be fetched because of a timeout error!')
      end
    end

    context 'when HTTP error has been raised' do
      before do
        stub_full_request(location).to_raise(Gitlab::HTTP::Error)
      end

      it 'returns error message about a HTTP error' do
        expect(subject).to eq('Remote file `https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.[MASKED]xxx.yml` could not be fetched because of HTTP error!')
      end
    end

    context 'when response has 404 status' do
      before do
        stub_full_request(location).to_return(body: remote_file_content, status: 404)
      end

      it 'returns error message about a timeout' do
        expect(subject).to eq('Remote file `https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.[MASKED]xxx.yml` could not be fetched because of HTTP code `404` error!')
      end
    end

    context 'when the URL is blocked' do
      let(:location) { 'http://127.0.0.1/some/path/to/config.yaml' }

      it 'includes details about blocked URL' do
        expect(subject).to eq "Remote file could not be fetched because URL " \
                              'is blocked: Requests to localhost are not allowed!'
      end
    end

    context 'when connection refused error has been raised' do
      let(:location) { 'http://127.0.0.1/some/path/to/config.yaml' }
      let(:exception) { Errno::ECONNREFUSED.new }

      before do
        stub_full_request(location).to_raise(exception)
      end

      it 'returns details about connection failure' do
        expect(subject).to eq "Remote file could not be fetched because Connection refused!"
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

  describe '#metadata' do
    before do
      stub_full_request(location).to_return(body: remote_file_content)
    end

    subject(:metadata) { remote_file.metadata }

    it do
      is_expected.to eq(
        context_project: nil,
        context_sha: '12345',
        type: :remote,
        location: 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.[MASKED]xxx.yml',
        raw: 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.[MASKED]xxx.yml',
        blob: nil,
        extra: {}
      )
    end
  end

  describe '#to_hash' do
    subject(:to_hash) do
      remote_file.preload_content
      remote_file.to_hash
    end

    before do
      stub_full_request(location).to_return(body: remote_file_content)
    end

    context 'with a valid remote file' do
      it 'returns the content as a hash' do
        expect(to_hash).to eql(
          before_script: ["apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs",
                          "ruby -v",
                          "which ruby",
                          "bundle install --jobs $(nproc)  \"${FLAGS[@]}\""]
        )
      end
    end

    context 'when it has `include` with rules:exists' do
      let(:remote_file_content) do
        <<~HEREDOC
        include:
          - local: another-file.yml
            rules:
              - exists: [Dockerfile]
        HEREDOC
      end

      it 'returns the content as a hash' do
        expect(to_hash).to eql(
          include: [
            { local: 'another-file.yml',
              rules: [{ exists: ['Dockerfile'] }] }
          ]
        )
      end
    end

    context 'when interpolation has been used' do
      let_it_be(:project) { create(:project) }

      let(:remote_file_content) do
        <<~YAML
        spec:
          inputs:
            include:
        ---
        include:
          - local: $[[ inputs.include ]]
            rules:
              - exists: [Dockerfile]
        YAML
      end

      let(:params) { { remote: location, inputs: { include: 'some-file.yml' } } }

      let(:context_params) do
        { sha: '12345', variables: variables, project: project, user: build(:user) }
      end

      it 'returns the content as a hash' do
        expect(remote_file).to be_valid
        expect(to_hash).to eql(
          include: [
            { local: 'some-file.yml',
              rules: [{ exists: ['Dockerfile'] }] }
          ]
        )
      end
    end
  end
end
