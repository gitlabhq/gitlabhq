# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Lint, feature_category: :pipeline_composition do
  let_it_be_with_refind(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:sha) { nil }
  let(:verify_project_sha) { nil }
  let(:ref) { project&.default_branch }
  let(:kwargs) do
    {
      project: project,
      current_user: user,
      sha: sha,
      verify_project_sha: verify_project_sha
    }.compact
  end

  let(:lint) { described_class.new(project: project, **kwargs) }

  describe '#validate' do
    subject { lint.validate(content, dry_run: dry_run, ref: ref) }

    shared_examples 'content is valid' do
      let(:content) do
        <<~YAML
        build:
          stage: build
          before_script:
            - before_build
          script: echo
          environment: staging
          when: manual
        rspec:
          stage: test
          script: rspec
          after_script:
            - after_rspec
          tags: [docker]
        YAML
      end

      it 'returns a valid result', :aggregate_failures do
        expect(subject).to be_valid

        expect(subject.errors).to be_empty
        expect(subject.warnings).to be_empty
        expect(subject.jobs).to be_present

        build_job = subject.jobs.first
        expect(build_job[:name]).to eq('build')
        expect(build_job[:stage]).to eq('build')
        expect(build_job[:before_script]).to eq(['before_build'])
        expect(build_job[:script]).to eq(['echo'])
        expect(build_job.fetch(:after_script)).to eq([])
        expect(build_job[:tag_list]).to eq([])
        expect(build_job[:environment]).to eq('staging')
        expect(build_job[:when]).to eq('manual')
        expect(build_job[:allow_failure]).to eq(true)

        rspec_job = subject.jobs.last
        expect(rspec_job[:name]).to eq('rspec')
        expect(rspec_job[:stage]).to eq('test')
        expect(rspec_job.fetch(:before_script)).to eq([])
        expect(rspec_job[:script]).to eq(['rspec'])
        expect(rspec_job[:after_script]).to eq(['after_rspec'])
        expect(rspec_job[:tag_list]).to eq(['docker'])
        expect(rspec_job.fetch(:environment)).to be_nil
        expect(rspec_job[:when]).to eq('on_success')
        expect(rspec_job[:allow_failure]).to eq(false)
      end
    end

    shared_examples 'sets config metadata' do
      let(:content) do
        <<~YAML
        :include:
          :local: another-gitlab-ci.yml
        :test_job:
          :stage: test
          :script: echo
        YAML
      end

      let(:included_content) do
        <<~YAML
        :another_job:
          :script: echo
        YAML
      end

      before do
        project.repository.create_file(
          project.creator,
          'another-gitlab-ci.yml',
          included_content,
          message: 'Automatically created another-gitlab-ci.yml',
          branch_name: 'master'
        )
      end

      after do
        project.repository.delete_file(
          project.creator,
          'another-gitlab-ci.yml',
          message: 'Remove another-gitlab-ci.yml',
          branch_name: 'master'
        )
      end

      it 'sets merged_config' do
        root_config = YAML.safe_load(content, permitted_classes: [Symbol])
        included_config = YAML.safe_load(included_content, permitted_classes: [Symbol])
        expected_config = included_config.merge(root_config).except(:include).deep_stringify_keys

        expect(subject.merged_yaml).to eq(expected_config.to_yaml)
      end

      it 'sets includes' do
        expect(subject.includes).to contain_exactly(
          {
            type: :local,
            location: 'another-gitlab-ci.yml',
            blob: "http://localhost/#{project.full_path}/-/blob/#{project.commit.sha}/another-gitlab-ci.yml",
            raw: "http://localhost/#{project.full_path}/-/raw/#{project.commit.sha}/another-gitlab-ci.yml",
            extra: {},
            context_project: project.full_path,
            context_sha: project.commit.sha
          }
        )
      end
    end

    shared_examples 'content with errors and warnings' do
      context 'when content has errors' do
        let(:content) do
          <<~YAML
          build:
            invalid: syntax
          YAML
        end

        it 'returns a result with errors' do
          expect(subject).not_to be_valid
          expect(subject.errors).to include(/jobs build config should implement the script:, run:, or trigger: keyword/)
        end
      end

      context 'when content has warnings' do
        let(:content) do
          <<~YAML
          rspec:
            script: rspec
            rules:
              - when: always
          YAML
        end

        it 'returns a result with warnings' do
          expect(subject).to be_valid
          expect(subject.warnings).to include(/rspec may allow multiple pipelines to run/)
        end
      end

      context 'when content has more warnings than max limit' do
        # content will result in 2 warnings
        let(:content) do
          <<~YAML
          rspec:
            script: rspec
            rules:
              - when: always
          rspec2:
            script: rspec
            rules:
              - when: always
          YAML
        end

        before do
          stub_const('Gitlab::Ci::Warnings::MAX_LIMIT', 1)
        end

        it 'returns a result with warnings' do
          expect(subject).to be_valid
          expect(subject.warnings.size).to eq(1)
        end
      end

      context 'when content has errors and warnings' do
        let(:content) do
          <<~YAML
          rspec:
            script: rspec
            rules:
              - when: always
          karma:
            script: karma
            unknown: key
          YAML
        end

        it 'returns a result with errors and warnings' do
          expect(subject).not_to be_valid
          expect(subject.errors).to include(/karma config contains unknown keys/)
          expect(subject.warnings).to include(/rspec may allow multiple pipelines to run/)
        end
      end
    end

    shared_context 'advanced validations' do
      let(:content) do
        <<~YAML
        build:
          stage: build
          script: echo
          rules:
            - if: '$CI_MERGE_REQUEST_ID'
        test:
          stage: test
          script: echo
          needs: [build]
        YAML
      end
    end

    context 'when a pipeline ref variable is used in an `include`' do
      let(:dry_run) { false }

      let(:content) do
        <<~YAML
          include:
            - project: "#{project.full_path}"
              ref: ${CI_COMMIT_REF_NAME}
              file: '.gitlab-ci-include.yml'

          show-parent-variable:
            stage : .pre
            script:
              - echo I am running a variable ${CI_COMMIT_REF_NAME}
        YAML
      end

      let(:included_content) do
        <<~YAML
          another_job:
            script: echo
        YAML
      end

      before do
        project.add_developer(user)

        project.repository.create_file(
          project.creator,
          '.gitlab-ci-include.yml',
          included_content,
          message: 'Add .gitlab-ci-include.yml',
          branch_name: 'master'
        )
      end

      after do
        project.repository.delete_file(
          project.creator,
          '.gitlab-ci-include.yml',
          message: 'Remove .gitlab-ci-include.yml',
          branch_name: 'master'
        )
      end

      it 'passes the ref name to YamlProcessor' do
        expect(Gitlab::Ci::YamlProcessor)
          .to receive(:new)
          .with(content, a_hash_including(ref: project.default_branch))
          .and_call_original

        expect(subject.includes).to contain_exactly(
          {
            type: :file,
            location: '.gitlab-ci-include.yml',
            blob: "http://localhost/#{project.full_path}/-/blob/#{project.commit.sha}/.gitlab-ci-include.yml",
            raw: "http://localhost/#{project.full_path}/-/raw/#{project.commit.sha}/.gitlab-ci-include.yml",
            extra: { project: project.full_path, ref: project.default_branch },
            context_project: project.full_path,
            context_sha: project.commit.sha
          }
        )
      end

      context 'when the ref is a tag' do
        before do
          project.repository.add_tag(project.creator, 'test', project.commit.id)
          allow(project.repository).to receive(:branch_names_contains).and_return([])
        end

        after do
          project.repository.rm_tag(project.creator, 'test')
        end

        it 'passes the ref name to YamlProcessor' do
          expect(Gitlab::Ci::YamlProcessor)
            .to receive(:new)
            .with(content, a_hash_including(ref: 'test'))
            .and_call_original

          expect(subject.includes).to contain_exactly(
            {
              type: :file,
              location: '.gitlab-ci-include.yml',
              blob: "http://localhost/#{project.full_path}/-/blob/#{project.commit.sha}/.gitlab-ci-include.yml",
              raw: "http://localhost/#{project.full_path}/-/raw/#{project.commit.sha}/.gitlab-ci-include.yml",
              extra: { project: project.full_path, ref: 'test' },
              context_project: project.full_path,
              context_sha: project.commit.sha
            }
          )
        end
      end
    end

    context 'when user has permissions to write the ref' do
      before do
        project.add_developer(user)
      end

      context 'when using default static mode' do
        let(:dry_run) { false }

        it_behaves_like 'content with errors and warnings'

        it_behaves_like 'content is valid' do
          it 'includes extra attributes' do
            subject.jobs.each do |job|
              expect(job[:only]).to eq(refs: %w[branches tags])
              expect(job.fetch(:except)).to be_nil
            end
          end
        end

        it_behaves_like 'sets config metadata'

        include_context 'advanced validations' do
          it 'does not catch advanced logical errors' do
            expect(subject).to be_valid
            expect(subject.errors).to be_empty
          end
        end

        it 'uses YamlProcessor' do
          expect(Gitlab::Ci::YamlProcessor)
            .to receive(:new)
            .and_call_original

          subject
        end

        shared_examples 'when sha is not provided' do
          it 'runs YamlProcessor with verify_project_sha: false' do
            expect(Gitlab::Ci::YamlProcessor)
              .to receive(:new)
              .with(content, a_hash_including(verify_project_sha: false))
              .and_call_original

            subject
          end
        end

        it_behaves_like 'when sha is not provided'

        context 'when the content contains protected variables' do
          let(:content) do
            <<~HEREDOC
            include:
              - 'https://test.example.com/${SECRET_TOKEN}.yml'

            rubocop:
              script:
                - bundle exec rubocop
            HEREDOC
          end

          before do
            create(:ci_variable, key: 'SECRET_TOKEN', value: 'secret!!!!!', project: project, protected: true)

            project.add_maintainer(user)

            stub_request(:get, "https://test.example.com/secret!!!!!.yml")
          end

          context 'when the ref is a protected branch' do
            before do
              create(:protected_branch, project: project, name: 'master')
            end

            it 'expands the protected variables' do
              expect(subject).not_to be_valid
              expect(subject.errors).to include(
                'Included file `https://test.example.com/secret!!!!!.yml` is empty or does not exist!'
              )
            end
          end

          context 'when the ref is a protected tag' do
            let(:sha) do
              project.repository.create_file(
                project.creator,
                'test.yml',
                '',
                message: 'Created test.yml',
                branch_name: 'new-branch'
              )
            end

            before do
              project.repository.add_tag(project.creator, '6.6.6', sha)
              project.repository.rm_branch(project.creator, 'new-branch')

              create(:protected_tag, project: project, name: '6.6.6')
            end

            after do
              project.repository.rm_tag(project.creator, '6.6.6')
            end

            # We don't mark pipelines as `tag` during static validation, so we never expand protected variables for
            # tags even if the tag is protected.
            it 'does not expand protected variables' do
              expect(subject).not_to be_valid
              expect(subject.errors).to include(
                'Included file `https://test.example.com/.yml` does not have YAML extension!'
              )
            end
          end
        end

        context 'when sha is provided' do
          let(:sha) { project.commit.sha }

          it 'runs YamlProcessor with verify_project_sha: true' do
            expect(Gitlab::Ci::YamlProcessor)
              .to receive(:new)
              .with(content, a_hash_including(verify_project_sha: true))
              .and_call_original

            subject
          end

          it_behaves_like 'content is valid'

          context 'when the sha is invalid' do
            let(:sha) { 'invalid-sha' }

            it_behaves_like 'content is valid'
          end

          context 'when the sha is from a fork' do
            include_context 'when a project repository contains a forked commit'

            let(:sha) { forked_commit_sha }

            context 'when a project ref contains the sha' do
              before do
                mock_branch_contains_forked_commit_sha
              end

              it_behaves_like 'content is valid'
            end

            context 'when a project ref does not contain the sha' do
              it 'returns an error' do
                expect(subject).not_to be_valid
                expect(subject.errors).to include(
                  /configuration originates from an external project or a commit not associated with a Git reference/)
              end
            end
          end

          context 'when verify_project_sha is false' do
            let(:verify_project_sha) { false }

            it_behaves_like 'when sha is not provided'
          end
        end
      end

      context 'when using dry run mode' do
        let(:dry_run) { true }

        it_behaves_like 'content with errors and warnings'

        it_behaves_like 'content is valid' do
          it 'does not include extra attributes' do
            subject.jobs.each do |job|
              expect(job.key?(:only)).to be_falsey
              expect(job.key?(:except)).to be_falsey
            end
          end
        end

        context 'when using a ref other than the default branch' do
          let(:ref) { 'feature' }
          let(:content) do
            <<~YAML
            build:
              stage: build
              script: echo 1
              rules:
                - if: "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"
            test:
              stage: test
              script: echo 2
              rules:
                - if: "$CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH"
            YAML
          end

          it 'includes only jobs that are excluded on the default branch' do
            expect(subject.jobs.size).to eq(1)
            expect(subject.jobs[0][:name]).to eq('test')
          end
        end

        it_behaves_like 'sets config metadata'

        include_context 'advanced validations' do
          it 'runs advanced logical validations' do
            expect(subject).not_to be_valid
            expect(subject.errors.first).to include(
              "'test' job needs 'build' job, but 'build' does not exist in the pipeline"
            )
          end
        end

        it 'uses Ci::CreatePipelineService' do
          expect(::Ci::CreatePipelineService)
            .to receive(:new)
            .and_call_original

          subject
        end
      end
    end

    context 'when user does not have permissions to write the ref' do
      let(:content) do
        <<~HEREDOC
        include:
          - 'https://test.example.com/${SECRET_TOKEN}.yml'

        rubocop:
          script:
            - bundle exec rubocop
        HEREDOC
      end

      before do
        project.add_reporter(user)
      end

      context 'when using default static mode' do
        let(:dry_run) { false }

        before do
          create(:ci_variable, key: 'SECRET_TOKEN', value: 'secret!!!!!', project: project, protected: true)
        end

        context 'when the ref is a protected branch' do
          before do
            sha = project.repository.commit.sha
            ref = Gitlab::Ci::RefFinder.new(project).find_by_sha(sha)

            create(:protected_branch, project: project, name: ref)
          end

          it 'does not expand protected variables' do
            expect(subject).not_to be_valid
            expect(subject.errors).to include(
              'Included file `https://test.example.com/.yml` does not have YAML extension!'
            )
          end
        end

        context 'when the ref is a protected tag' do
          let(:sha) do
            project.repository.create_file(
              project.creator,
              'test.yml',
              '',
              message: 'Created test.yml',
              branch_name: 'new-branch'
            )
          end

          before do
            project.repository.add_tag(project.creator, '6.6.6', sha)
            project.repository.rm_branch(project.creator, 'new-branch')

            create(:protected_tag, project: project, name: '6.6.6')
          end

          after do
            project.repository.rm_tag(project.creator, '6.6.6')
          end

          it 'does not expand protected variables' do
            expect(subject).not_to be_valid
            expect(subject.errors).to include(
              'Included file `https://test.example.com/.yml` does not have YAML extension!'
            )
          end
        end
      end

      context 'when using dry run mode' do
        let(:dry_run) { true }

        let(:content) do
          <<~YAML
          job:
            script: echo
          YAML
        end

        it 'does not allow validation' do
          expect(subject).not_to be_valid
          expect(subject.errors).to include('Insufficient permissions to create a new pipeline')
        end
      end
    end
  end

  describe 'pipeline logger' do
    let(:expected_data) do
      {
        'class' => 'Gitlab::Ci::Pipeline::Logger',
        'config_build_context_duration_s' => a_kind_of(Numeric),
        'config_build_variables_duration_s' => a_kind_of(Numeric),
        'config_root_duration_s' => a_kind_of(Numeric),
        'config_root_compose_duration_s' => a_kind_of(Numeric),
        'config_root_compose_jobs_factory_duration_s' => a_kind_of(Numeric),
        'config_root_compose_jobs_create_duration_s' => a_kind_of(Numeric),
        'config_expand_duration_s' => a_kind_of(Numeric),
        'config_external_process_duration_s' => a_kind_of(Numeric),
        'config_stages_inject_duration_s' => a_kind_of(Numeric),
        'config_tags_resolve_duration_s' => a_kind_of(Numeric),
        'config_yaml_extend_duration_s' => a_kind_of(Numeric),
        'config_yaml_load_duration_s' => a_kind_of(Numeric),
        'pipeline_creation_caller' => 'Gitlab::Ci::Lint',
        'pipeline_creation_service_duration_s' => a_kind_of(Numeric),
        'pipeline_persisted' => false,
        'pipeline_source' => 'unknown',
        'project_id' => project&.id,
        'yaml_process_duration_s' => a_kind_of(Numeric)
      }
    end

    let(:content) do
      <<~YAML
      build:
        script: echo
      YAML
    end

    subject(:validate) { lint.validate(content, dry_run: false) }

    before do
      project&.add_developer(user)
    end

    context 'when the duration is under the threshold' do
      it 'does not create a log entry' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        validate
      end
    end

    context 'when the durations exceeds the threshold' do
      let(:timer) do
        proc do
          @timer = @timer.to_i + 30
        end
      end

      before do
        allow(Gitlab::Ci::Pipeline::Logger)
          .to receive(:current_monotonic_time) { timer.call }
      end

      it 'creates a log entry' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(a_hash_including(expected_data))

        validate
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(ci_pipeline_creation_logger: false)
        end

        it 'does not create a log entry' do
          expect(Gitlab::AppJsonLogger).not_to receive(:info)

          validate
        end
      end

      context 'when project is not provided' do
        let(:lint) { described_class.new(project: nil, **kwargs) }

        let(:project_nil_loggable_data) do
          expected_data.except('project_id')
        end

        it 'creates a log entry without project_id' do
          expect(Gitlab::AppJsonLogger).to receive(:info).with(a_hash_including(project_nil_loggable_data))

          validate
        end
      end
    end
  end
end
