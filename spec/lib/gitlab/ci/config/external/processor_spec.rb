# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Processor do
  include StubRequests

  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_reload(:another_project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:sha) { '12345' }
  let(:context_params) { { project: project, sha: sha, user: user } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }
  let(:processor) { described_class.new(values, context) }

  before do
    project.add_developer(user)

    allow_any_instance_of(Gitlab::Ci::Config::External::Context)
      .to receive(:check_execution_time!)
  end

  describe "#perform" do
    subject(:perform) { processor.perform }

    context 'when no external files defined' do
      let(:values) { { image: 'image:1.0' } }

      it 'returns the same values' do
        expect(processor.perform).to eq(values)
      end
    end

    context 'when an invalid local file is defined' do
      let(:values) { { include: '/lib/gitlab/ci/templates/non-existent-file.yml', image: 'image:1.0' } }

      it 'raises an error' do
        expect { processor.perform }.to raise_error(
          described_class::IncludeError,
          "Local file `/lib/gitlab/ci/templates/non-existent-file.yml` does not exist!"
        )
      end
    end

    context 'when an invalid remote file is defined' do
      let(:remote_file) { 'http://doesntexist.com/.gitlab-ci-1.yml' }
      let(:values) { { include: remote_file, image: 'image:1.0' } }

      before do
        stub_full_request(remote_file).and_raise(SocketError.new('Some HTTP error'))
      end

      it 'raises an error' do
        expect { processor.perform }.to raise_error(
          described_class::IncludeError,
          "Remote file `#{remote_file}` could not be fetched because of a socket error!"
        )
      end
    end

    context 'with a valid remote external file is defined' do
      let(:remote_file) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
      let(:values) { { include: remote_file, image: 'image:1.0' } }
      let(:external_file_content) do
        <<-HEREDOC
        before_script:
          - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
          - ruby -v
          - which ruby
          - bundle install --jobs $(nproc)  "${FLAGS[@]}"

        rspec:
          script:
            - bundle exec rspec

        rubocop:
          script:
            - bundle exec rubocop
        HEREDOC
      end

      before do
        stub_full_request(remote_file).to_return(body: external_file_content)
      end

      it 'appends the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :before_script, :rspec, :rubocop])
      end

      it "removes the 'include' keyword" do
        expect(processor.perform[:include]).to be_nil
      end
    end

    context 'with a valid local external file is defined' do
      let(:values) { { include: '/lib/gitlab/ci/templates/template.yml', image: 'image:1.0' } }
      let(:local_file_content) do
        <<-HEREDOC
        before_script:
          - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
          - ruby -v
          - which ruby
          - bundle install --jobs $(nproc)  "${FLAGS[@]}"
        HEREDOC
      end

      before do
        allow_any_instance_of(Gitlab::Ci::Config::External::File::Local)
          .to receive(:fetch_local_content).and_return(local_file_content)
      end

      it 'appends the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :before_script])
      end

      it "removes the 'include' keyword" do
        expect(processor.perform[:include]).to be_nil
      end
    end

    context 'with multiple external files are defined' do
      let(:remote_file) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
      let(:external_files) do
        [
          '/spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml',
          remote_file
        ]
      end

      let(:values) do
        {
          include: external_files,
          image: 'image:1.0'
        }
      end

      let(:remote_file_content) do
        <<-HEREDOC
        stages:
          - build
          - review
          - cleanup
        HEREDOC
      end

      before do
        local_file_content = File.read(Rails.root.join('spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml'))

        allow_any_instance_of(Gitlab::Ci::Config::External::File::Local)
          .to receive(:fetch_local_content).and_return(local_file_content)

        stub_full_request(remote_file).to_return(body: remote_file_content)
      end

      it 'appends the files to the values' do
        expect(processor.perform.keys).to match_array([:image, :stages, :before_script, :rspec])
      end

      it "removes the 'include' keyword" do
        expect(processor.perform[:include]).to be_nil
      end
    end

    context 'when external files are defined but not valid' do
      let(:values) { { include: '/lib/gitlab/ci/templates/template.yml', image: 'image:1.0' } }

      let(:local_file_content) { 'invalid content file ////' }

      before do
        allow_any_instance_of(Gitlab::Ci::Config::External::File::Local)
          .to receive(:fetch_local_content).and_return(local_file_content)
      end

      it 'raises an error' do
        expect { processor.perform }.to raise_error(
          described_class::IncludeError,
          "Included file `/lib/gitlab/ci/templates/template.yml` does not have valid YAML syntax!"
        )
      end
    end

    context "when both external files and values defined the same key" do
      let(:remote_file) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
      let(:values) do
        {
          include: remote_file,
          image: 'image:1.0'
        }
      end

      let(:remote_file_content) do
        <<~HEREDOC
        image: php:5-fpm-alpine
        HEREDOC
      end

      it 'takes precedence' do
        stub_full_request(remote_file).to_return(body: remote_file_content)

        expect(processor.perform[:image]).to eq('image:1.0')
      end
    end

    context "when a nested includes are defined" do
      let(:values) do
        {
          include: [
            { local: '/local/file.yml' }
          ],
          image: 'image:1.0'
        }
      end

      before do
        allow(project.repository).to receive(:blob_data_at).with('12345', '/local/file.yml') do
          <<~HEREDOC
            include:
              - template: Ruby.gitlab-ci.yml
              - remote: http://my.domain.com/config.yml
              - project: #{another_project.full_path}
                file: /templates/my-workflow.yml
          HEREDOC
        end

        allow_any_instance_of(Repository).to receive(:blob_data_at).with(another_project.commit.id, '/templates/my-workflow.yml') do
          <<~HEREDOC
            include:
              - local: /templates/my-build.yml
          HEREDOC
        end

        allow_any_instance_of(Repository).to receive(:blob_data_at).with(another_project.commit.id, '/templates/my-build.yml') do
          <<~HEREDOC
            my_build:
              script: echo Hello World
          HEREDOC
        end

        stub_full_request('http://my.domain.com/config.yml')
          .to_return(body: 'remote_build: { script: echo Hello World }')
      end

      context 'when project is public' do
        before do
          another_project.update!(visibility: 'public')
        end

        it 'properly expands all includes' do
          is_expected.to include(:my_build, :remote_build, :rspec)
        end

        it 'propagates the pipeline logger' do
          processor.perform

          process_obs_count = processor
            .logger
            .observations_hash
            .dig('config_mapper_process_duration_s', 'count')

          expect(process_obs_count).to eq(3)
        end

        it 'stores includes' do
          perform

          expect(context.includes).to contain_exactly(
            { type: :local,
              location: '/local/file.yml',
              blob: "http://localhost/#{project.full_path}/-/blob/12345/local/file.yml",
              raw: "http://localhost/#{project.full_path}/-/raw/12345/local/file.yml",
              extra: {},
              context_project: project.full_path,
              context_sha: '12345' },
            { type: :template,
              location: 'Ruby.gitlab-ci.yml',
              blob: nil,
              raw: 'https://gitlab.com/gitlab-org/gitlab/-/raw/master/lib/gitlab/ci/templates/Ruby.gitlab-ci.yml',
              extra: {},
              context_project: project.full_path,
              context_sha: '12345' },
            { type: :remote,
              location: 'http://my.domain.com/config.yml',
              blob: nil,
              raw: "http://my.domain.com/config.yml",
              extra: {},
              context_project: project.full_path,
              context_sha: '12345' },
            { type: :file,
              location: '/templates/my-workflow.yml',
              blob: "http://localhost/#{another_project.full_path}/-/blob/#{another_project.commit.sha}/templates/my-workflow.yml",
              raw: "http://localhost/#{another_project.full_path}/-/raw/#{another_project.commit.sha}/templates/my-workflow.yml",
              extra: { project: another_project.full_path, ref: 'HEAD' },
              context_project: project.full_path,
              context_sha: '12345' },
            { type: :local,
              location: '/templates/my-build.yml',
              blob: "http://localhost/#{another_project.full_path}/-/blob/#{another_project.commit.sha}/templates/my-build.yml",
              raw: "http://localhost/#{another_project.full_path}/-/raw/#{another_project.commit.sha}/templates/my-build.yml",
              extra: {},
              context_project: another_project.full_path,
              context_sha: another_project.commit.sha }
          )
        end
      end

      context 'when user is reporter of another project' do
        before do
          another_project.add_reporter(user)
        end

        it 'properly expands all includes' do
          is_expected.to include(:my_build, :remote_build, :rspec)
        end
      end

      context 'when user is not allowed' do
        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Ci::Config::External::Processor::IncludeError, /not found or access denied/)
        end
      end

      context 'when too many includes is included' do
        it 'raises an error' do
          allow(context).to receive(:max_includes).and_return(1)

          expect { subject }.to raise_error(Gitlab::Ci::Config::External::Processor::IncludeError, /Maximum of 1 nested/)
        end
      end
    end

    context 'when config includes an external configuration file via SSL web request' do
      before do
        stub_full_request('https://sha256.badssl.com/fake.yml', ip_address: '8.8.8.8')
          .to_return(body: 'image: image:1.0', status: 200)

        stub_full_request('https://self-signed.badssl.com/fake.yml', ip_address: '8.8.8.9')
          .to_raise(OpenSSL::SSL::SSLError.new('SSL_connect returned=1 errno=0 state=error: certificate verify failed (self signed certificate)'))
      end

      context 'with an acceptable certificate' do
        let(:values) { { include: 'https://sha256.badssl.com/fake.yml' } }

        it { is_expected.to include(image: 'image:1.0') }
      end

      context 'with a self-signed certificate' do
        let(:values) { { include: 'https://self-signed.badssl.com/fake.yml' } }

        it 'returns a reportable configuration error' do
          expect { subject }.to raise_error(described_class::IncludeError, /certificate verify failed/)
        end
      end
    end

    context 'when a valid project file is defined' do
      let(:values) do
        {
          include: { project: another_project.full_path, file: '/templates/my-build.yml' },
          image: 'image:1.0'
        }
      end

      before do
        another_project.add_developer(user)

        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:blob_data_at).with(another_project.commit.id, '/templates/my-build.yml') do
            <<~HEREDOC
              my_build:
                script: echo Hello World
            HEREDOC
          end
        end
      end

      it 'appends the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :my_build])
      end
    end

    context 'when valid project files are defined in a single include' do
      let(:values) do
        {
          include: {
            project: another_project.full_path,
            file: ['/templates/my-build.yml', '/templates/my-test.yml']
          },
          image: 'image:1.0'
        }
      end

      before do
        another_project.add_developer(user)

        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:blob_data_at).with(another_project.commit.id, '/templates/my-build.yml') do
            <<~HEREDOC
              my_build:
                script: echo Hello World
            HEREDOC
          end

          allow(repository).to receive(:blob_data_at).with(another_project.commit.id, '/templates/my-test.yml') do
            <<~HEREDOC
              my_test:
                script: echo Hello World
            HEREDOC
          end
        end
      end

      it 'appends the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :my_build, :my_test])
      end

      it 'stores includes' do
        perform

        expect(context.includes).to contain_exactly(
          { type: :file,
            location: '/templates/my-build.yml',
            blob: "http://localhost/#{another_project.full_path}/-/blob/#{another_project.commit.sha}/templates/my-build.yml",
            raw: "http://localhost/#{another_project.full_path}/-/raw/#{another_project.commit.sha}/templates/my-build.yml",
            extra: { project: another_project.full_path, ref: 'HEAD' },
            context_project: project.full_path,
            context_sha: '12345' },
          { type: :file,
            blob: "http://localhost/#{another_project.full_path}/-/blob/#{another_project.commit.sha}/templates/my-test.yml",
            raw: "http://localhost/#{another_project.full_path}/-/raw/#{another_project.commit.sha}/templates/my-test.yml",
            location: '/templates/my-test.yml',
            extra: { project: another_project.full_path, ref: 'HEAD' },
            context_project: project.full_path,
            context_sha: '12345' }
        )
      end
    end

    context 'when local file path has wildcard' do
      let(:project) { create(:project, :repository) }

      let(:values) do
        { include: 'myfolder/*.yml', image: 'image:1.0' }
      end

      before do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:search_files_by_wildcard_path).with('myfolder/*.yml', sha) do
            ['myfolder/file1.yml', 'myfolder/file2.yml']
          end

          allow(repository).to receive(:blob_data_at).with(sha, 'myfolder/file1.yml') do
            <<~HEREDOC
              my_build:
                script: echo Hello World
            HEREDOC
          end

          allow(repository).to receive(:blob_data_at).with(sha, 'myfolder/file2.yml') do
            <<~HEREDOC
              my_test:
                script: echo Hello World
            HEREDOC
          end
        end
      end

      it 'fetches the matched files' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :my_build, :my_test])
      end

      it 'stores includes' do
        perform

        expect(context.includes).to contain_exactly(
          { type: :local,
            location: 'myfolder/file1.yml',
            blob: "http://localhost/#{project.full_path}/-/blob/12345/myfolder/file1.yml",
            raw: "http://localhost/#{project.full_path}/-/raw/12345/myfolder/file1.yml",
            extra: {},
            context_project: project.full_path,
            context_sha: '12345' },
          { type: :local,
            blob: "http://localhost/#{project.full_path}/-/blob/12345/myfolder/file2.yml",
            raw: "http://localhost/#{project.full_path}/-/raw/12345/myfolder/file2.yml",
            location: 'myfolder/file2.yml',
            extra: {},
            context_project: project.full_path,
            context_sha: '12345' }
        )
      end
    end

    context 'when rules defined' do
      context 'when a rule is invalid' do
        let(:values) do
          { include: [{ local: 'builds.yml', rules: [{ changes: ['$MY_VAR'] }] }] }
        end

        it 'raises IncludeError' do
          expect { subject }.to raise_error(described_class::IncludeError, /invalid include rule/)
        end
      end
    end
  end
end
