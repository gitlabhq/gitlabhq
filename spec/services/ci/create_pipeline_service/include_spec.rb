# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :pipeline_composition do
  include RepoHelpers

  context 'include:' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.first_owner }

    let(:ref)                  { 'refs/heads/master' }
    let(:variables_attributes) { [{ key: 'MYVAR', value: 'hello' }] }
    let(:source)               { :push }

    let(:service)  { described_class.new(project, user, { ref: ref, variables_attributes: variables_attributes }) }
    let(:pipeline) { service.execute(source).payload }

    let_it_be(:file_location) { 'spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml' }

    let(:project_files) do
      {
        '.gitlab-ci.yml' => config,
        file_location => File.read(Rails.root.join(file_location))
      }
    end

    around do |example|
      create_and_delete_files(project, project_files) do
        example.run
      end
    end

    before do
      project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
    end

    shared_examples 'not including the file' do
      it 'does not include the job in the file' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.processables.pluck(:name)).to contain_exactly('job')
      end
    end

    shared_examples 'including the file' do
      it 'includes the job in the file' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.processables.pluck(:name)).to contain_exactly('job', 'rspec')
      end
    end

    context 'with a local file' do
      let(:config) do
        <<~EOY
        include: #{file_location}
        job:
          script: exit 0
        EOY
      end

      it_behaves_like 'including the file'
    end

    context 'with a local file with rules with a project variable' do
      let(:config) do
        <<~EOY
        include:
          - local: #{file_location}
            rules:
              - if: $CI_PROJECT_ID == "#{project_id}"
        job:
          script: exit 0
        EOY
      end

      context 'when the rules matches' do
        let(:project_id) { project.id }

        it_behaves_like 'including the file'
      end

      context 'when the rules does not match' do
        let(:project_id) { non_existing_record_id }

        it_behaves_like 'not including the file'
      end
    end

    context 'with a local file with rules with a predefined pipeline variable' do
      let(:config) do
        <<~EOY
        include:
          - local: #{file_location}
            rules:
              - if: $CI_PIPELINE_SOURCE == "#{pipeline_source}"
        job:
          script: exit 0
        EOY
      end

      context 'when the rules matches' do
        let(:pipeline_source) { 'push' }

        it_behaves_like 'including the file'
      end

      context 'when the rules does not match' do
        let(:pipeline_source) { 'web' }

        it_behaves_like 'not including the file'
      end
    end

    context 'with a local file with rules with a run pipeline variable' do
      let(:config) do
        <<~EOY
        include:
          - local: #{file_location}
            rules:
              - if: $MYVAR == "#{my_var}"
        job:
          script: exit 0
        EOY
      end

      context 'when the rules matches' do
        let(:my_var) { 'hello' }

        it_behaves_like 'including the file'
      end

      context 'when the rules does not match' do
        let(:my_var) { 'mello' }

        it_behaves_like 'not including the file'
      end
    end

    context 'with a local file with rules:exists' do
      let(:config) do
        <<~YAML
        include:
          - local: file1.yml
            rules:
              - exists:
                - 'docs/*.md' # does not match
                - 'config/*.rb' # does not match
          - local: file2.yml
            rules:
              - exists:
                - 'docs/*.md' # does not match
                - '**/app.rb' # does not match
          - local: #{file_location}
            rules:
              - exists:
                - '**/app.rb' # does not match
                - spec/fixtures/gitlab/ci/*/.gitlab-ci-template-1.yml # matches

        job:
          script: exit 0
        YAML
      end

      let(:number_of_files) { project.repository.ls_files(ref).size }

      it_behaves_like 'including the file'

      context 'on checking cache', :request_store do
        it 'does not evaluate the same glob more than once' do
          expect(File).to receive(:fnmatch?)
            .with('docs/*.md', anything, anything)
            .exactly(number_of_files).times # it iterates all files
            .and_call_original
          expect(File).to receive(:fnmatch?)
            .with('config/*.rb', anything, anything)
            .exactly(number_of_files).times # it iterates all files
            .and_call_original
          expect(File).to receive(:fnmatch?)
            .with('**/app.rb', anything, anything)
            .exactly(number_of_files).times # it iterates all files
            .and_call_original
          expect(File).to receive(:fnmatch?)
            .with('spec/fixtures/gitlab/ci/*/.gitlab-ci-template-1.yml', anything, anything)
            .exactly(39).times # it iterates files until it finds a match
            .and_call_original

          expect(pipeline).to be_created_successfully
          expect(pipeline.processables.pluck(:name)).to contain_exactly('job', 'rspec')
        end
      end
    end

    context 'with Gitaly timeout handling' do
      before do
        stub_const('Gitlab::Ci::Config::GITALY_TIMEOUT_SECONDS', 0.0001)
      end

      context 'when local include times out' do
        let(:config) do
          <<~YAML
          include:
            - local: #{file_location}
          job:
            script: exit 0
          YAML
        end

        it 'fails with timeout error' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          expect(pipeline).to be_persisted
          expect(pipeline.error_messages.map(&:content)).to include(
            'CI configuration fetch from Gitaly timed out. This may indicate Gitaly service slowness or an outage.'
          )
        end

        context 'when ci_config_gitaly_timeout feature flag is disabled' do
          before do
            stub_feature_flags(ci_config_gitaly_timeout: false)
          end

          it_behaves_like 'including the file'
        end
      end

      context 'when project include times out' do
        let_it_be(:another_project) { create(:project, :repository, :public) }

        let(:included_file_content) { File.read(Rails.root.join(file_location)) }

        let(:config) do
          <<~YAML
          include:
            - project: #{another_project.full_path}
              file: /#{file_location}
          job:
            script: exit 0
          YAML
        end

        before_all do
          another_project.repository.create_file(
            another_project.creator,
            file_location,
            File.read(Rails.root.join(file_location)),
            message: 'Add CI template',
            branch_name: 'master'
          )
        end

        it 'fails with timeout error' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          expect(pipeline).to be_persisted
          expect(pipeline.error_messages.map(&:content)).to include(
            'CI configuration fetch from Gitaly timed out. This may indicate Gitaly service slowness or an outage.'
          )
        end

        context 'when ci_config_gitaly_timeout feature flag is disabled' do
          before do
            stub_feature_flags(ci_config_gitaly_timeout: false)
          end

          it_behaves_like 'including the file'
        end
      end

      context 'when multiple includes exceed the cumulative fetch timeout' do
        let_it_be(:other_project1) { create(:project, :repository, :public) }
        let_it_be(:other_project2) { create(:project, :repository, :public) }

        let(:config) do
          <<~YAML
          include:
            - local: templates/ci-1.yml
            - project: #{other_project1.full_path}
              file: /templates/ci-2.yml
            - project: #{other_project2.full_path}
              file: /templates/ci-3.yml
          job:
            script: exit 0
          YAML
        end

        let(:project_files) do
          {
            '.gitlab-ci.yml' => config,
            'templates/ci-1.yml' => "local_job_templates_ci-1.yml:\n  script: echo templates/ci-1.yml"
          }
        end

        before_all do
          other_project1.repository.create_file(
            other_project1.creator,
            'templates/ci-2.yml',
            "remote_job_templates_ci-2.yml:\n  script: echo templates/ci-2.yml",
            message: "Add templates/ci-2.yml",
            branch_name: 'master'
          )
          other_project2.repository.create_file(
            other_project2.creator,
            'templates/ci-3.yml',
            "remote_job_templates_ci-3.yml:\n  script: echo templates/ci-3.yml",
            message: "Add templates/ci-3.yml",
            branch_name: 'master'
          )
        end

        before do
          stub_feature_flags(ci_config_fetch_timeout_override: false)
          stub_const('Gitlab::Ci::Config::TIMEOUT_SECONDS', 0.3.seconds) # it should take at least 0.3 seconds (0.1 x 3)
          stub_const('Gitlab::Ci::Config::GITALY_TIMEOUT_SECONDS', 1) # allowing it run as log as it takes

          allow_any_instance_of(Repository).to receive(:blobs_at).and_wrap_original do |method, *args| # rubocop:disable RSpec/AnyInstanceOf -- needed to intercept calls across multiple repositories
            sleep 0.1
            method.call(*args)
          end
        end

        it 'fails with the cumulative fetch timeout error' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          expect(pipeline).to be_persisted
          expect(pipeline.error_messages.map(&:content)).to include(
            Gitlab::Ci::Config::TIMEOUT_MESSAGE
          )
        end
      end
    end

    context 'with HTTP timeout handling' do
      include StubRequests

      let(:remote_url) { 'https://example.com/ci-template.yml' }

      let(:config) do
        <<~YAML
        include:
          - remote: #{remote_url}
        job:
          script: exit 0
        YAML
      end

      before do
        stub_full_request(remote_url).to_timeout
      end

      it 'fails with timeout error' do
        expect(pipeline).to be_persisted
        expect(pipeline.error_messages.map(&:content)).to include(
          "Remote file `#{remote_url}` could not be fetched after 3 attempts because of a timeout error!"
        )
      end

      context 'when ci_config_http_timeout feature flag is disabled' do
        before do
          stub_feature_flags(ci_config_http_timeout: false)
        end

        it 'fails with timeout error' do
          expect(pipeline).to be_persisted
          expect(pipeline.error_messages.map(&:content)).to include(
            "Remote file `#{remote_url}` could not be fetched after 3 attempts because of a timeout error!"
          )
        end
      end
    end
  end
end
