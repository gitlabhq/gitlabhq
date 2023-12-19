# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Processor, feature_category: :pipeline_composition do
  include StubRequests
  include RepoHelpers

  let_it_be(:user) { create(:user) }

  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be_with_reload(:another_project) { create(:project, :repository) }

  let(:project_files) { {} }
  let(:other_project_files) { {} }

  let(:sha) { project.commit.sha }
  let(:context_params) { { project: project, sha: sha, user: user } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }

  subject(:processor) { described_class.new(values, context) }

  around do |example|
    create_and_delete_files(project, project_files) do
      create_and_delete_files(another_project, other_project_files) do
        example.run
      end
    end
  end

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
          "Local file `lib/gitlab/ci/templates/non-existent-file.yml` does not exist!"
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
        <<-YAML
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
        YAML
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

    context 'when the remote file has `include` with rules:exists' do
      let(:remote_file) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
      let(:values) { { include: remote_file, image: 'image:1.0' } }
      let(:external_file_content) do
        <<-YAML
        include:
          - local: another-file.yml
            rules:
              - exists: [Dockerfile]

        rspec:
          script:
            - bundle exec rspec
        YAML
      end

      before do
        stub_full_request(remote_file).to_return(body: external_file_content)
      end

      it 'evaluates the rule as false' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :rspec])
      end

      it "removes the 'include' keyword" do
        expect(processor.perform[:include]).to be_nil
      end
    end

    context 'with a valid local external file is defined' do
      let(:values) { { include: '/lib/gitlab/ci/templates/template.yml', image: 'image:1.0' } }
      let(:local_file_content) do
        <<-YAML
        before_script:
          - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
          - ruby -v
          - which ruby
          - bundle install --jobs $(nproc)  "${FLAGS[@]}"
        YAML
      end

      let(:project_files) { { '/lib/gitlab/ci/templates/template.yml' => local_file_content } }

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

      let(:local_file_content) do
        File.read(Rails.root.join('spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml'))
      end

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
        <<-YAML
        stages:
          - build
          - review
          - cleanup
        YAML
      end

      let(:project_files) do
        {
          '/spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml' => local_file_content
        }
      end

      before do
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

      let(:project_files) { { '/lib/gitlab/ci/templates/template.yml' => local_file_content } }

      it 'raises an error' do
        expect { processor.perform }.to raise_error(
          described_class::IncludeError,
          '`lib/gitlab/ci/templates/template.yml`: Invalid configuration format'
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
        <<~YAML
        image: php:5-fpm-alpine
        YAML
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

      let(:project_files) do
        {
          '/local/file.yml' => <<~YAML
          include:
            - template: Ruby.gitlab-ci.yml
            - remote: http://my.domain.com/config.yml
            - project: #{another_project.full_path}
              file: /templates/my-workflow.yml
          YAML
        }
      end

      let(:other_project_files) do
        {
          '/templates/my-workflow.yml' => <<~YAML,
          include:
            - local: /templates/my-build.yml
          YAML
          '/templates/my-build.yml' => <<~YAML
          my_build:
            script: echo Hello World
          YAML
        }
      end

      before do
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
              location: 'local/file.yml',
              blob: "http://localhost/#{project.full_path}/-/blob/#{sha}/local/file.yml",
              raw: "http://localhost/#{project.full_path}/-/raw/#{sha}/local/file.yml",
              extra: {},
              context_project: project.full_path,
              context_sha: sha },
            { type: :template,
              location: 'Ruby.gitlab-ci.yml',
              blob: nil,
              raw: 'https://gitlab.com/gitlab-org/gitlab/-/raw/master/lib/gitlab/ci/templates/Ruby.gitlab-ci.yml',
              extra: {},
              context_project: project.full_path,
              context_sha: sha },
            { type: :remote,
              location: 'http://my.domain.com/config.yml',
              blob: nil,
              raw: "http://my.domain.com/config.yml",
              extra: {},
              context_project: project.full_path,
              context_sha: sha },
            { type: :file,
              location: 'templates/my-workflow.yml',
              blob: "http://localhost/#{another_project.full_path}/-/blob/#{another_project.commit.sha}/templates/my-workflow.yml",
              raw: "http://localhost/#{another_project.full_path}/-/raw/#{another_project.commit.sha}/templates/my-workflow.yml",
              extra: { project: another_project.full_path, ref: 'HEAD' },
              context_project: project.full_path,
              context_sha: sha },
            { type: :local,
              location: 'templates/my-build.yml',
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

    describe 'include:component' do
      let(:values) do
        {
          include: { component: "#{Gitlab.config.gitlab.host}/#{another_project.full_path}/component-x@master" },
          image: 'image:1.0'
        }
      end

      let(:other_project_files) do
        {
          '/templates/component-x/template.yml' => <<~YAML
          component_x_job:
            script: echo Component X
          YAML
        }
      end

      before do
        another_project.add_developer(user)
      end

      it 'appends the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :component_x_job])
      end
    end

    context 'when a valid project file is defined' do
      let(:values) do
        {
          include: { project: another_project.full_path, file: '/templates/my-build.yml' },
          image: 'image:1.0'
        }
      end

      let(:other_project_files) do
        {
          '/templates/my-build.yml' => <<~YAML
          my_build:
            script: echo Hello World
          YAML
        }
      end

      before do
        another_project.add_developer(user)
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

      let(:other_project_files) do
        {
          '/templates/my-build.yml' => <<~YAML,
          my_build:
            script: echo Hello World
          YAML
          '/templates/my-test.yml' => <<~YAML
          my_test:
            script: echo Hello World
          YAML
        }
      end

      before do
        another_project.add_developer(user)
      end

      it 'appends the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :my_build, :my_test])
      end

      it 'stores includes' do
        perform

        expect(context.includes).to contain_exactly(
          { type: :file,
            location: 'templates/my-build.yml',
            blob: "http://localhost/#{another_project.full_path}/-/blob/#{another_project.commit.sha}/templates/my-build.yml",
            raw: "http://localhost/#{another_project.full_path}/-/raw/#{another_project.commit.sha}/templates/my-build.yml",
            extra: { project: another_project.full_path, ref: 'HEAD' },
            context_project: project.full_path,
            context_sha: sha },
          { type: :file,
            blob: "http://localhost/#{another_project.full_path}/-/blob/#{another_project.commit.sha}/templates/my-test.yml",
            raw: "http://localhost/#{another_project.full_path}/-/raw/#{another_project.commit.sha}/templates/my-test.yml",
            location: 'templates/my-test.yml',
            extra: { project: another_project.full_path, ref: 'HEAD' },
            context_project: project.full_path,
            context_sha: sha }
        )
      end
    end

    context 'when local file path has wildcard' do
      let(:values) do
        { include: 'myfolder/*.yml', image: 'image:1.0' }
      end

      let(:project_files) do
        {
          'myfolder/file1.yml' => <<~YAML,
          my_build:
            script: echo Hello World
          YAML
          'myfolder/file2.yml' => <<~YAML
          my_test:
            script: echo Hello World
          YAML
        }
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
            blob: "http://localhost/#{project.full_path}/-/blob/#{sha}/myfolder/file1.yml",
            raw: "http://localhost/#{project.full_path}/-/raw/#{sha}/myfolder/file1.yml",
            extra: {},
            context_project: project.full_path,
            context_sha: sha },
          { type: :local,
            blob: "http://localhost/#{project.full_path}/-/blob/#{sha}/myfolder/file2.yml",
            raw: "http://localhost/#{project.full_path}/-/raw/#{sha}/myfolder/file2.yml",
            location: 'myfolder/file2.yml',
            extra: {},
            context_project: project.full_path,
            context_sha: sha }
        )
      end
    end

    context 'when rules defined' do
      context 'when a rule is invalid' do
        let(:values) do
          { include: [{ local: 'builds.yml', rules: [{ allow_failure: ['$MY_VAR'] }] }] }
        end

        it 'raises IncludeError' do
          expect { subject }.to raise_error(described_class::IncludeError, /contains unknown keys: allow_failure/)
        end
      end
    end
  end
end
