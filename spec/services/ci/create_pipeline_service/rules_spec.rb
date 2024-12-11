# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :pipeline_composition do
  include Ci::PipelineMessageHelpers

  let(:project)     { create(:project, :repository) }
  let(:user)        { project.first_owner }
  let(:ref)         { 'refs/heads/master' }
  let(:source)      { :push }
  let(:service)     { described_class.new(project, user, initialization_params) }
  let(:response)    { service.execute(source) }
  let(:pipeline)    { response.payload }
  let(:build_names) { pipeline.builds.pluck(:name) }

  let(:base_initialization_params) { { ref: ref, before: '00000000', after: project.commit(ref).sha, variables_attributes: nil } }
  let(:initialization_params)      { base_initialization_params }

  before do
    project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
  end

  context 'job:rules' do
    let(:regular_job) { find_job('regular-job') }
    let(:rules_job)   { find_job('rules-job') }
    let(:delayed_job) { find_job('delayed-job') }

    def find_job(name)
      pipeline.builds.find_by(name: name)
    end

    shared_examples 'rules jobs are excluded' do
      it 'only persists the job without rules' do
        expect(pipeline).to be_persisted
        expect(regular_job).to be_persisted
        expect(rules_job).to be_nil
        expect(delayed_job).to be_nil
      end
    end

    before do
      stub_ci_pipeline_yaml_file(config)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |instance|
        allow(instance).to receive(:perform).and_return(true)
      end
    end

    context 'exists:' do
      let(:config) do
        <<-EOY
        regular-job:
          script: 'echo Hello, World!'

        rules-job:
          script: "echo hello world, $CI_COMMIT_REF_NAME"
          rules:
            - exists:
              - README.md
              when: manual
            - exists:
              - app.rb
              when: on_success

        delayed-job:
          script: "echo See you later, World!"
          rules:
            - exists:
              - README.md
              when: delayed
              start_in: 4 hours
        EOY
      end

      let(:regular_job) { pipeline.builds.find_by(name: 'regular-job') }
      let(:rules_job)   { pipeline.builds.find_by(name: 'rules-job') }
      let(:delayed_job) { pipeline.builds.find_by(name: 'delayed-job') }

      context 'with matches' do
        let(:project) { create(:project, :custom_repo, files: { 'README.md' => '' }) }

        it 'creates two jobs' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('regular-job', 'rules-job', 'delayed-job')
        end

        it 'sets when: for all jobs' do
          expect(regular_job.when).to eq('on_success')
          expect(rules_job.when).to eq('manual')
          expect(delayed_job.when).to eq('delayed')
          expect(delayed_job.options[:start_in]).to eq('4 hours')
        end
      end

      context 'with matches on the second rule' do
        let(:project) { create(:project, :custom_repo, files: { 'app.rb' => '' }) }

        it 'includes both jobs' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('regular-job', 'rules-job')
        end

        it 'sets when: for the created rules job based on the second clause' do
          expect(regular_job.when).to eq('on_success')
          expect(rules_job.when).to eq('on_success')
        end
      end

      context 'without matches' do
        let(:project) { create(:project, :custom_repo, files: { 'useless_script.rb' => '' }) }

        it 'only persists the job without rules' do
          expect(pipeline).to be_persisted
          expect(regular_job).to be_persisted
          expect(rules_job).to be_nil
          expect(delayed_job).to be_nil
        end

        it 'sets when: for the created job' do
          expect(regular_job.when).to eq('on_success')
        end
      end
    end

    context 'exists with patterns' do
      let(:config) do
        <<-YAML
        job1:
          script: echo Hello, World!
          rules:
            - exists:
              - 'docs/*.md' # does not match
              - 'config/*.rb' # matches

        job2:
          script: echo Hello, World!
          rules:
            - exists:
              - 'docs/*.md' # does not match
              - '**/app.rb' # matches

        job3:
          script: echo Hello, World!
          rules:
            - exists:
              - 'config/*.yml' # does not match
              - '**/app.rb' # matches

        job4:
          script: echo Hello, World!
          rules:
            - exists:
              - '**/app.rb' # matches
        YAML
      end

      context 'with matches' do
        let_it_be(:project_files) do
          {
            'config/app.rb' => '',
            'hello1.yml' => '',
            'hello2.yml' => ''
          }
        end

        let_it_be(:project) do
          create(:project, :custom_repo, files: project_files)
        end

        let_it_be(:number_of_project_files) { project_files.size }

        it 'creates all jobs' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('job1', 'job2', 'job3', 'job4')
        end

        context 'on checking cache', :request_store do
          it 'does not evaluate the same glob more than once' do
            expect(File).to receive(:fnmatch?)
              .with('docs/*.md', anything, anything)
              .exactly(number_of_project_files).times # it iterates all files
              .and_call_original
            expect(File).to receive(:fnmatch?)
              .with('config/*.rb', anything, anything)
              .once # it iterates once and finds the file
              .and_call_original
            expect(File).to receive(:fnmatch?)
              .with('config/*.yml', anything, anything)
              .exactly(number_of_project_files).times # it iterates all files
              .and_call_original
            expect(File).to receive(:fnmatch?)
              .with('**/app.rb', anything, anything)
              .once # it iterates once and finds the file
              .and_call_original

            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly('job1', 'job2', 'job3', 'job4')
          end
        end
      end
    end

    context 'exists with variables' do
      let(:config) do
        <<-YAML
        variables:
          VAR_DIRECTORY: "config"
          VAR_FILE: "app.rb"
          VAR_COMBINED: "config/app.rb"
          VAR_COMBINED_NO_MATCH: "temp/app.rb"
          VAR_NESTED: $VAR_DIRECTORY/$VAR_FILE

        job1:
          script: echo Hello, World!
          rules:
            - exists:
              - $VAR_DIRECTORY/$VAR_FILE # matches

        job2:
          script: echo Hello, World!
          rules:
            - exists:
              - $VAR_COMBINED # matches

        job3:
          script: echo Hello, World!
          rules:
            - exists:
              - $VAR_COMBINED_NO_MATCH # does not match

        job4:
          script: echo Hello, World!
          rules:
            - exists:
              - $VAR_NESTED
        YAML
      end

      context 'with matches' do
        let_it_be(:project_files) do
          {
            'config/app.rb' => '',
            'some_file.rb' => ''
          }
        end

        let_it_be(:project) do
          create(:project, :custom_repo, files: project_files)
        end

        let_it_be(:number_of_project_files) { project_files.size }

        it 'creates all relevant jobs' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('job1', 'job2', 'job4')
        end
      end
    end

    context 'with allow_failure and exit_codes', :aggregate_failures do
      let(:config) do
        <<-EOY
          job-1:
            script: exit 42
            allow_failure:
              exit_codes: 42
            rules:
              - if: $CI_COMMIT_REF_NAME == "master"
                allow_failure: false

          job-2:
            script: exit 42
            allow_failure:
              exit_codes: 42
            rules:
              - if: $CI_COMMIT_REF_NAME == "master"
                allow_failure: true

          job-3:
            script: exit 42
            allow_failure:
              exit_codes: 42
            rules:
              - if: $CI_COMMIT_REF_NAME == "master"
                when: manual
        EOY
      end

      it 'creates a pipeline' do
        expect(pipeline).to be_persisted
        expect(build_names).to contain_exactly(
          'job-1', 'job-2', 'job-3'
        )
      end

      it 'assigns job:allow_failure values to the builds' do
        expect(find_job('job-1').allow_failure).to eq(false)
        expect(find_job('job-2').allow_failure).to eq(true)
        expect(find_job('job-3').allow_failure).to eq(false)
      end

      it 'removes exit_codes if allow_failure is specified' do
        expect(find_job('job-1').options[:allow_failure_criteria]).to be_nil
        expect(find_job('job-2').options[:allow_failure_criteria]).to be_nil
        expect(find_job('job-3').options.dig(:allow_failure_criteria, :exit_codes)).to eq([42])
      end
    end

    context 'if:' do
      context 'variables:' do
        let(:config) do
          <<-EOY
          variables:
            VAR4: workflow var 4
            VAR5: workflow var 5
            VAR7: workflow var 7

          workflow:
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                variables:
                  VAR4: overridden workflow var 4
              - if: $CI_COMMIT_REF_NAME =~ /feature/
                variables:
                  VAR5: overridden workflow var 5
                  VAR6: new workflow var 6
                  VAR7: overridden workflow var 7
              - when: always

          job1:
            script: "echo job1"
            variables:
              VAR1: job var 1
              VAR2: job var 2
              VAR5: job var 5
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                variables:
                  VAR1: overridden var 1
              - if: $CI_COMMIT_REF_NAME =~ /feature/
                variables:
                  VAR2: overridden var 2
                  VAR3: new var 3
                  VAR7: overridden var 7
              - when: on_success

          job2:
            script: "echo job2"
            inherit:
              variables: [VAR4, VAR6, VAR7]
            variables:
              VAR4: job var 4
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                variables:
                  VAR7: overridden var 7
              - when: on_success
          EOY
        end

        let(:job1) { pipeline.builds.find_by(name: 'job1') }
        let(:job2) { pipeline.builds.find_by(name: 'job2') }

        let(:variable_keys) { %w[VAR1 VAR2 VAR3 VAR4 VAR5 VAR6 VAR7] }

        context 'when no match' do
          let(:ref) { 'refs/heads/wip' }

          it 'does not affect vars' do
            expect(job1.scoped_variables.to_hash.values_at(*variable_keys)).to eq(
              ['job var 1', 'job var 2', nil, 'workflow var 4', 'job var 5', nil, 'workflow var 7']
            )

            expect(job2.scoped_variables.to_hash.values_at(*variable_keys)).to eq(
              [nil, nil, nil, 'job var 4', nil, nil, 'workflow var 7']
            )
          end
        end

        context 'when matching to the first rule' do
          let(:ref) { 'refs/heads/master' }

          it 'overrides variables' do
            expect(job1.scoped_variables.to_hash.values_at(*variable_keys)).to eq(
              ['overridden var 1', 'job var 2', nil, 'overridden workflow var 4', 'job var 5', nil, 'workflow var 7']
            )

            expect(job2.scoped_variables.to_hash.values_at(*variable_keys)).to eq(
              [nil, nil, nil, 'job var 4', nil, nil, 'overridden var 7']
            )
          end
        end

        context 'when matching to the second rule' do
          let(:ref) { 'refs/heads/feature' }

          it 'overrides variables' do
            expect(job1.scoped_variables.to_hash.values_at(*variable_keys)).to eq(
              ['job var 1', 'overridden var 2', 'new var 3', 'workflow var 4', 'job var 5', 'new workflow var 6', 'overridden var 7']
            )

            expect(job2.scoped_variables.to_hash.values_at(*variable_keys)).to eq(
              [nil, nil, nil, 'job var 4', nil, 'new workflow var 6', 'overridden workflow var 7']
            )
          end
        end

        context 'using calculated workflow var in job rules' do
          let(:config) do
            <<-EOY
            variables:
              VAR1: workflow var 4

            workflow:
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  variables:
                    VAR1: overridden workflow var 4
                - when: always

            job:
              script: "echo job1"
              rules:
                - if: $VAR1 =~ "overridden workflow var 4"
                  variables:
                    VAR1: overridden var 1
                - when: on_success
            EOY
          end

          let(:job) { pipeline.builds.find_by(name: 'job') }

          context 'when matching the first workflow condition' do
            let(:ref) { 'refs/heads/master' }

            it 'uses VAR1 of job rules result' do
              expect(job.scoped_variables.to_hash['VAR1']).to eq('overridden var 1')
            end
          end
        end
      end

      context 'with CI_ENVIRONMENT_* predefined variables' do
        let(:config) do
          <<-EOY
          deploy:
            script: "deploy"
            environment:
              name: review/$CI_COMMIT_REF_NAME
              deployment_tier: development
              url: https://gitlab.com
            rules:
              - if: $CI_ENVIRONMENT_NAME =~ /^review\// && $CI_ENVIRONMENT_ACTION == "start" && $CI_ENVIRONMENT_TIER == "development" && $CI_ENVIRONMENT_URL == "https://gitlab.com"

          teardown:
            script: "teardown"
            environment:
              name: review/$CI_COMMIT_REF_NAME
              deployment_tier: development
              url: https://gitlab.com
              action: stop
            rules:
              - if: $CI_ENVIRONMENT_NAME =~ /^review\// && $CI_ENVIRONMENT_ACTION == "stop" && $CI_ENVIRONMENT_TIER == "development" && $CI_ENVIRONMENT_URL == "https://gitlab.com"
                when: manual
          EOY
        end

        it 'assigns correct attributes to the jobs' do
          expect(pipeline).to be_persisted

          BatchLoader::Executor.clear_current

          expect(build_names).to contain_exactly('deploy', 'teardown')
          expect(find_job('deploy').when).to eq('on_success')
          expect(find_job('teardown').when).to eq('manual')
          expect(find_job('deploy').allow_failure).to eq(false)
          expect(find_job('teardown').allow_failure).to eq(false)
          expect(find_job('deploy').actual_persisted_environment.name).to eq('review/master')
          expect(find_job('teardown').actual_persisted_environment.name).to eq('review/master')
        end
      end

      context 'with simple if: clauses' do
        let(:config) do
          <<-EOY
            regular-job:
              script: 'echo Hello, World!'

            master-job:
              script: "echo hello world, $CI_COMMIT_REF_NAME"
              rules:
                - if: $CI_COMMIT_REF_NAME == "nonexistant-branch"
                  when: never
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  when: manual

            negligible-job:
              script: "exit 1"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  allow_failure: true

            delayed-job:
              script: "echo See you later, World!"
              rules:
                - if: $CI_COMMIT_REF_NAME =~ /master/
                  when: delayed
                  start_in: 1 hour

            never-job:
              script: "echo Goodbye, World!"
              rules:
                - if: $CI_COMMIT_REF_NAME
                  when: never
          EOY
        end

        context 'with matches' do
          it 'creates a pipeline with the vanilla and manual jobs' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly(
              'regular-job', 'delayed-job', 'master-job', 'negligible-job'
            )
          end

          it 'assigns job:when values to the builds' do
            expect(find_job('regular-job').when).to eq('on_success')
            expect(find_job('master-job').when).to eq('manual')
            expect(find_job('negligible-job').when).to eq('on_success')
            expect(find_job('delayed-job').when).to eq('delayed')
          end

          it 'assigns job:allow_failure values to the builds' do
            expect(find_job('regular-job').allow_failure).to eq(false)
            expect(find_job('master-job').allow_failure).to eq(false)
            expect(find_job('negligible-job').allow_failure).to eq(true)
            expect(find_job('delayed-job').allow_failure).to eq(false)
          end

          it 'assigns start_in for delayed jobs' do
            expect(delayed_job.options[:start_in]).to eq('1 hour')
          end
        end

        context 'with no matches' do
          let(:ref) { 'refs/heads/feature' }

          it_behaves_like 'rules jobs are excluded'
        end
      end

      context 'with complex if: clauses' do
        let(:config) do
          <<-EOY
            regular-job:
              script: 'echo Hello, World!'
              rules:
                - if: $VAR == 'present' && $OTHER || $CI_COMMIT_REF_NAME
                  when: manual
                  allow_failure: true
          EOY
        end

        it 'matches the first rule' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('regular-job')
          expect(regular_job.when).to eq('manual')
          expect(regular_job.allow_failure).to eq(true)
        end
      end

      context 'with needs:' do
        let(:config) do
          <<-EOY
            job1:
              script: ls

            job2:
              script: ls
              rules:
                - if: $var == null
                  needs: [job1]
                - when: on_success

            job3:
              script: ls
              rules:
                - if: $var == null
                  needs: [job1]
                - needs: [job2]

            job4:
              script: ls
              needs: [job1]
              rules:
                - if: $var == null
                  needs: [job2]
                - when: on_success
                  needs: [job3]
          EOY
        end

        let(:job1) { pipeline.builds.find_by(name: 'job1') }
        let(:job2) { pipeline.builds.find_by(name: 'job2') }
        let(:job3) { pipeline.builds.find_by(name: 'job3') }
        let(:job4) { pipeline.builds.find_by(name: 'job4') }

        context 'when the `$var` rule matches' do
          it 'creates a pipeline with overridden needs' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly('job1', 'job2', 'job3', 'job4')

            expect(job1.needs).to be_empty
            expect(job2.needs).to contain_exactly(an_object_having_attributes(name: 'job1'))
            expect(job3.needs).to contain_exactly(an_object_having_attributes(name: 'job1'))
            expect(job4.needs).to contain_exactly(an_object_having_attributes(name: 'job2'))
          end
        end

        context 'when the `$var` rule does not match' do
          let(:initialization_params) { base_initialization_params.merge(variables_attributes: variables_attributes) }

          let(:variables_attributes) do
            [{ key: 'var', secret_value: 'SOME_VAR' }]
          end

          it 'creates a pipeline with overridden needs' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly('job1', 'job2', 'job3', 'job4')

            expect(job1.needs).to be_empty
            expect(job2.needs).to be_empty
            expect(job3.needs).to contain_exactly(an_object_having_attributes(name: 'job2'))
            expect(job4.needs).to contain_exactly(an_object_having_attributes(name: 'job3'))
          end
        end
      end
    end

    context 'changes:' do
      let(:config) do
        <<-EOY
          regular-job:
            script: 'echo Hello, World!'

          rules-job:
            script: "echo hello world, $CI_COMMIT_REF_NAME"
            rules:
              - changes:
                - README.md
                when: manual
              - changes:
                - app.rb
                when: on_success

          delayed-job:
            script: "echo See you later, World!"
            rules:
              - changes:
                - README.md
                when: delayed
                start_in: 4 hours

          negligible-job:
            script: "can be failed sometimes"
            rules:
              - changes:
                - README.md
                allow_failure: true

          README:
            script: "I use variables for changes!"
            rules:
              - changes:
                - $CI_JOB_NAME*

          changes-paths:
            script: "I am using a new syntax!"
            rules:
              - changes:
                  paths: [README.md]
        EOY
      end

      context 'and matches' do
        before do
          allow_next_instance_of(Ci::Pipeline) do |pipeline|
            allow(pipeline).to receive(:modified_paths).and_return(%w[README.md])
          end
        end

        it 'creates five jobs' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly(
            'regular-job', 'rules-job', 'delayed-job', 'negligible-job', 'README', 'changes-paths'
          )
        end

        it 'sets when: for all jobs' do
          expect(regular_job.when).to eq('on_success')
          expect(rules_job.when).to eq('manual')
          expect(delayed_job.when).to eq('delayed')
          expect(delayed_job.options[:start_in]).to eq('4 hours')
        end

        it 'sets allow_failure: for negligible job' do
          expect(find_job('negligible-job').allow_failure).to eq(true)
        end
      end

      context 'and matches the second rule' do
        before do
          allow_next_instance_of(Ci::Pipeline) do |pipeline|
            allow(pipeline).to receive(:modified_paths).and_return(%w[app.rb])
          end
        end

        it 'includes both jobs' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('regular-job', 'rules-job')
        end

        it 'sets when: for the created rules job based on the second clause' do
          expect(regular_job.when).to eq('on_success')
          expect(rules_job.when).to eq('on_success')
        end
      end

      context 'and does not match' do
        before do
          allow_next_instance_of(Ci::Pipeline) do |pipeline|
            allow(pipeline).to receive(:modified_paths).and_return(%w[useless_script.rb])
          end
        end

        it_behaves_like 'rules jobs are excluded'

        it 'sets when: for the created job' do
          expect(regular_job.when).to eq('on_success')
        end
      end

      context 'with paths and compare_to' do
        let_it_be(:project) { create(:project, :empty_repo) }
        let_it_be(:user)    { project.first_owner }

        before_all do
          project.repository.add_branch(user, 'feature_1', 'master')

          project.repository.create_file(
            user, 'file1.txt', 'file 1', message: 'Create file1.txt', branch_name: 'feature_1'
          )

          project.repository.add_branch(user, 'feature_2', 'feature_1')

          project.repository.create_file(
            user, 'file2.txt', 'file 2', message: 'Create file2.txt', branch_name: 'feature_2'
          )
        end

        let(:initialization_params) { base_initialization_params.merge(before: nil) }
        let(:changed_file) { 'file2.txt' }
        let(:ref) { 'feature_2' }

        context 'for jobs rules' do
          let(:config) do
            <<-EOY
            job1:
              script: exit 0
              rules:
                - changes:
                    paths: [#{changed_file}]
                    compare_to: #{compare_to}

            job2:
              script: exit 0
            EOY
          end

          context 'when there is no such compare_to ref' do
            let(:compare_to) { 'invalid-branch' }

            it 'returns an error' do
              expect(pipeline.errors.full_messages).to eq(
                [
                  'Failed to parse rule for job1: rules:changes:compare_to is not a valid ref'
                ])
            end
          end

          context 'when the compare_to ref exists' do
            let(:compare_to) { 'feature_1' }

            context 'when the rule matches' do
              it 'creates job1 and job2' do
                expect(build_names).to contain_exactly('job1', 'job2')
              end
            end

            context 'when the rule does not match' do
              let(:changed_file) { 'file1.txt' }

              it 'does not create job1' do
                expect(build_names).to contain_exactly('job2')
              end
            end
          end

          context 'for jobs rules with variables' do
            let(:config) do
              <<-EOY
              variables:
                VALID_BRANCH_NAME: feature_1
                FEATURE_BRANCH_NAME_PREFIX: feature_
                INVALID_BRANCH_NAME: invalid-branch
                VALID_FILENAME: file2.txt
                INVALID_FILENAME: file1.txt
                VALID_BASENAME: file2
                VALID_NESTED_VARIABLE: ${VALID_BASENAME}.txt
              job1:
                script: exit 0
                rules:
                  - changes:
                      paths: [#{changed_file}]
                      compare_to: #{compare_to}

              job2:
                script: exit 0
              EOY
            end

            context 'when there is no such compare_to ref' do
              let(:compare_to) { '${INVALID_BRANCH_NAME}' }

              it 'returns an error' do
                expect(pipeline.errors.full_messages).to eq(
                  ['Failed to parse rule for job1: rules:changes:compare_to is not a valid ref']
                )
              end
            end

            context 'when the compare_to ref exists' do
              let(:compare_to) { '${FEATURE_BRANCH_NAME_PREFIX}1' }

              context 'when the rule in job1 matches' do
                it 'creates job1 and job2' do
                  expect(build_names).to contain_exactly('job1', 'job2')
                end
              end

              context 'when the rule in job1 does not match' do
                let(:changed_file) { 'file1.txt' }

                it 'does not create job1' do
                  expect(build_names).to contain_exactly('job2')
                end
              end
            end

            context 'when the compare_to variable does not exist' do
              let(:compare_to) { '$NON_EXISTENT_VAR' }

              it 'returns an error' do
                expect(pipeline.errors.full_messages).to eq(
                  ['Failed to parse rule for job1: rules:changes:compare_to is not a valid ref']
                )
              end
            end

            context 'when paths is defined by a variable' do
              let(:compare_to) { '${VALID_BRANCH_NAME}' }

              context 'when the variable does not exist' do
                let(:changed_file) { '$NON_EXISTENT_VAR' }

                it 'does not create job1' do
                  expect(build_names).to contain_exactly('job2')
                end
              end

              context 'when the variable contains a matching filename' do
                let(:changed_file) { '$VALID_FILENAME' }

                it 'creates both jobs' do
                  expect(build_names).to contain_exactly('job1', 'job2')
                end
              end

              context 'when the variable does not contain a matching filename' do
                let(:changed_file) { '$INVALID_FILENAME' }

                it 'does not create job1' do
                  expect(build_names).to contain_exactly('job2')
                end
              end

              context 'when the variable is nested and contains a matching filename' do
                let(:changed_file) { '$VALID_NESTED_VARIABLE' }

                it 'creates both jobs' do
                  expect(build_names).to contain_exactly('job1', 'job2')
                end
              end
            end
          end
        end

        context 'for workflow rules' do
          let(:config) do
            <<-EOY
            workflow:
              rules:
                - changes:
                    paths: [#{changed_file}]
                    compare_to: #{compare_to}

            job1:
              script: exit 0
            EOY
          end

          let(:compare_to) { 'feature_1' }

          context 'when the rule matches' do
            it 'creates job1' do
              expect(pipeline).to be_created_successfully
              expect(build_names).to contain_exactly('job1')
            end
          end

          context 'when the rule does not match' do
            let(:changed_file) { 'file1.txt' }

            it 'does not create job1' do
              expect(pipeline).not_to be_created_successfully
              expect(build_names).to be_empty
            end
          end
        end
      end
    end

    context 'mixed if: and changes: rules' do
      let(:config) do
        <<-EOY
          regular-job:
            script: 'echo Hello, World!'

          rules-job:
            script: "echo hello world, $CI_COMMIT_REF_NAME"
            allow_failure: true
            rules:
              - changes:
                - README.md
                when: manual
              - if: $CI_COMMIT_REF_NAME == "master"
                when: on_success
                allow_failure: false

          delayed-job:
            script: "echo See you later, World!"
            rules:
              - changes:
                - README.md
                when: delayed
                start_in: 4 hours
                allow_failure: true
              - if: $CI_COMMIT_REF_NAME == "master"
                when: delayed
                start_in: 1 hour
        EOY
      end

      context 'and changes: matches before if' do
        before do
          allow_next_instance_of(Ci::Pipeline) do |pipeline|
            allow(pipeline).to receive(:modified_paths).and_return(%w[README.md])
          end
        end

        it 'creates two jobs' do
          expect(pipeline).to be_persisted
          expect(build_names)
            .to contain_exactly('regular-job', 'rules-job', 'delayed-job')
        end

        it 'sets when: for all jobs' do
          expect(regular_job.when).to eq('on_success')
          expect(rules_job.when).to eq('manual')
          expect(delayed_job.when).to eq('delayed')
          expect(delayed_job.options[:start_in]).to eq('4 hours')
        end

        it 'sets allow_failure: for all jobs' do
          expect(regular_job.allow_failure).to eq(false)
          expect(rules_job.allow_failure).to eq(true)
          expect(delayed_job.allow_failure).to eq(true)
        end
      end

      context 'and if: matches after changes' do
        it 'includes both jobs' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('regular-job', 'rules-job', 'delayed-job')
        end

        it 'sets when: for the created rules job based on the second clause' do
          expect(regular_job.when).to eq('on_success')
          expect(rules_job.when).to eq('on_success')
          expect(delayed_job.when).to eq('delayed')
          expect(delayed_job.options[:start_in]).to eq('1 hour')
        end
      end

      context 'and does not match' do
        let(:ref) { 'refs/heads/wip' }

        it_behaves_like 'rules jobs are excluded'

        it 'sets when: for the created job' do
          expect(regular_job.when).to eq('on_success')
        end
      end
    end

    context 'mixed if: and changes: clauses' do
      let(:config) do
        <<-EOY
          regular-job:
            script: 'echo Hello, World!'

          rules-job:
            script: "echo hello world, $CI_COMMIT_REF_NAME"
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                changes: [README.md]
                when: on_success
                allow_failure: true
              - if: $CI_COMMIT_REF_NAME =~ /master/
                changes: [app.rb]
                when: manual
        EOY
      end

      context 'with if matches and changes matches' do
        before do
          allow_next_instance_of(Ci::Pipeline) do |pipeline|
            allow(pipeline).to receive(:modified_paths).and_return(%w[app.rb])
          end
        end

        it 'persists all jobs' do
          expect(pipeline).to be_persisted
          expect(regular_job).to be_persisted
          expect(rules_job).to be_persisted
          expect(rules_job.when).to eq('manual')
          expect(rules_job.allow_failure).to eq(false)
        end
      end

      context 'with if matches and no change matches' do
        it_behaves_like 'rules jobs are excluded'
      end

      context 'with change matches and no if matches' do
        let(:ref) { 'refs/heads/feature' }

        before do
          allow_next_instance_of(Ci::Pipeline) do |pipeline|
            allow(pipeline).to receive(:modified_paths).and_return(%w[README.md])
          end
        end

        it_behaves_like 'rules jobs are excluded'
      end

      context 'and no matches' do
        let(:ref) { 'refs/heads/feature' }

        it_behaves_like 'rules jobs are excluded'
      end
    end

    context 'complex if: allow_failure usages' do
      let(:config) do
        <<-EOY
          job-1:
            script: "exit 1"
            allow_failure: true
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                allow_failure: false

          job-2:
            script: "exit 1"
            allow_failure: true
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /nonexistant-branch/
                allow_failure: false

          job-3:
            script: "exit 1"
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /nonexistant-branch/
                allow_failure: true

          job-4:
            script: "exit 1"
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                allow_failure: false

          job-5:
            script: "exit 1"
            allow_failure: false
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                allow_failure: true

          job-6:
            script: "exit 1"
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /nonexistant-branch/
                allow_failure: false
              - allow_failure: true
        EOY
      end

      it 'creates a pipeline' do
        expect(pipeline).to be_persisted
        expect(build_names).to contain_exactly('job-1', 'job-4', 'job-5', 'job-6')
      end

      it 'assigns job:allow_failure values to the builds' do
        expect(find_job('job-1').allow_failure).to eq(false)
        expect(find_job('job-4').allow_failure).to eq(false)
        expect(find_job('job-5').allow_failure).to eq(true)
        expect(find_job('job-6').allow_failure).to eq(true)
      end
    end

    context 'complex if: allow_failure & when usages' do
      let(:config) do
        <<-EOY
          job-1:
            script: "exit 1"
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                when: manual

          job-2:
            script: "exit 1"
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                when: manual
                allow_failure: true

          job-3:
            script: "exit 1"
            allow_failure: true
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                when: manual

          job-4:
            script: "exit 1"
            allow_failure: true
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                when: manual
                allow_failure: false

          job-5:
            script: "exit 1"
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /nonexistant-branch/
                when: manual
                allow_failure: false
              - when: always
                allow_failure: true

          job-6:
            script: "exit 1"
            allow_failure: false
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                when: manual

          job-7:
            script: "exit 1"
            allow_failure: false
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /nonexistant-branch/
                when: manual
              - when: :on_failure
                allow_failure: true
        EOY
      end

      it 'creates a pipeline' do
        expect(pipeline).to be_persisted
        expect(build_names).to contain_exactly(
          'job-1', 'job-2', 'job-3', 'job-4', 'job-5', 'job-6', 'job-7'
        )
      end

      it 'assigns job:allow_failure values to the builds' do
        expect(find_job('job-1').allow_failure).to eq(false)
        expect(find_job('job-2').allow_failure).to eq(true)
        expect(find_job('job-3').allow_failure).to eq(true)
        expect(find_job('job-4').allow_failure).to eq(false)
        expect(find_job('job-5').allow_failure).to eq(true)
        expect(find_job('job-6').allow_failure).to eq(false)
        expect(find_job('job-7').allow_failure).to eq(true)
      end

      it 'assigns job:when values to the builds' do
        expect(find_job('job-1').when).to eq('manual')
        expect(find_job('job-2').when).to eq('manual')
        expect(find_job('job-3').when).to eq('manual')
        expect(find_job('job-4').when).to eq('manual')
        expect(find_job('job-5').when).to eq('always')
        expect(find_job('job-6').when).to eq('manual')
        expect(find_job('job-7').when).to eq('on_failure')
      end
    end

    context 'deploy freeze period `if:` clause' do
      # '0 23 * * 5' == "At 23:00 on Friday."", '0 7 * * 1' == "At 07:00 on Monday.""
      let!(:freeze_period) { create(:ci_freeze_period, project: project, freeze_start: '0 23 * * 5', freeze_end: '0 7 * * 1') }

      context 'with 2 jobs' do
        let(:config) do
          <<-EOY
          stages:
            - test
            - deploy

          test-job:
            script:
              - echo 'running TEST stage'

          deploy-job:
            stage: deploy
            script:
              - echo 'running DEPLOY stage'
            rules:
              - if: $CI_DEPLOY_FREEZE == null
          EOY
        end

        context 'when outside freeze period' do
          it 'creates two jobs' do
            travel_to(Time.utc(2020, 4, 10, 22, 59)) do
              expect(pipeline).to be_persisted
              expect(build_names).to contain_exactly('test-job', 'deploy-job')
            end
          end
        end

        context 'when inside freeze period' do
          it 'creates one job' do
            travel_to(Time.utc(2020, 4, 10, 23, 1)) do
              expect(pipeline).to be_persisted
              expect(build_names).to contain_exactly('test-job')
            end
          end
        end
      end

      context 'with 1 job' do
        let(:config) do
          <<-EOY
          stages:
            - deploy

          deploy-job:
            stage: deploy
            script:
              - echo 'running DEPLOY stage'
            rules:
              - if: $CI_DEPLOY_FREEZE == null
          EOY
        end

        context 'when outside freeze period' do
          it 'creates two jobs' do
            travel_to(Time.utc(2020, 4, 10, 22, 59)) do
              expect(pipeline).to be_persisted
              expect(build_names).to contain_exactly('deploy-job')
            end
          end
        end

        context 'when inside freeze period' do
          it 'does not create the pipeline', :aggregate_failures do
            travel_to(Time.utc(2020, 4, 10, 23, 1)) do
              expect(response).to be_error
              expect(pipeline).not_to be_persisted
            end
          end
        end
      end
    end

    context 'with when:manual' do
      let(:config) do
        <<-EOY
        job-with-rules:
          script: 'echo hey'
          rules:
            - if: $CI_COMMIT_REF_NAME =~ /master/

        job-when-with-rules:
          script: 'echo hey'
          when: manual
          rules:
            - if: $CI_COMMIT_REF_NAME =~ /master/

        job-when-with-rules-when:
          script: 'echo hey'
          when: manual
          rules:
            - if: $CI_COMMIT_REF_NAME =~ /master/
              when: on_success

        job-with-rules-when:
          script: 'echo hey'
          rules:
            - if: $CI_COMMIT_REF_NAME =~ /master/
              when: manual

        job-without-rules:
          script: 'echo this is a job with NO rules'
        EOY
      end

      let(:job_with_rules) { find_job('job-with-rules') }
      let(:job_when_with_rules) { find_job('job-when-with-rules') }
      let(:job_when_with_rules_when) { find_job('job-when-with-rules-when') }
      let(:job_with_rules_when) { find_job('job-with-rules-when') }
      let(:job_without_rules) { find_job('job-without-rules') }

      context 'when matching the rules' do
        let(:ref) { 'refs/heads/master' }

        it 'adds the job-with-rules with a when:manual' do
          expect(job_with_rules).to be_persisted
          expect(job_when_with_rules).to be_persisted
          expect(job_when_with_rules_when).to be_persisted
          expect(job_with_rules_when).to be_persisted
          expect(job_without_rules).to be_persisted

          expect(job_with_rules.when).to eq('on_success')
          expect(job_when_with_rules.when).to eq('manual')
          expect(job_when_with_rules_when.when).to eq('on_success')
          expect(job_with_rules_when.when).to eq('manual')
          expect(job_without_rules.when).to eq('on_success')
        end
      end

      context 'when there is no match to the rule' do
        let(:ref) { 'refs/heads/wip' }

        it 'does not add job_with_rules' do
          expect(job_with_rules).to be_nil
          expect(job_when_with_rules).to be_nil
          expect(job_when_with_rules_when).to be_nil
          expect(job_with_rules_when).to be_nil
          expect(job_without_rules).to be_persisted
        end
      end
    end
  end

  context 'when workflow:rules are used' do
    before do
      stub_ci_pipeline_yaml_file(config)
    end

    context 'with a single regex-matching if: clause' do
      let(:config) do
        <<-EOY
          workflow:
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
              - if: $CI_COMMIT_REF_NAME =~ /wip$/
                when: never
              - if: $CI_COMMIT_REF_NAME =~ /feature/

          regular-job:
            script: 'echo Hello, World!'
        EOY
      end

      context 'matching the first rule in the list' do
        it 'saves a created pipeline' do
          expect(pipeline).to be_created
          expect(pipeline).to be_persisted
        end
      end

      context 'matching the last rule in the list' do
        let(:ref) { 'refs/heads/feature' }

        it 'saves a created pipeline' do
          expect(pipeline).to be_created
          expect(pipeline).to be_persisted
        end
      end

      context 'matching the when:never rule' do
        let(:ref) { 'refs/heads/wip' }

        it 'invalidates the pipeline with a workflow rules error' do
          expect(pipeline.errors[:base]).to include(sanitize_message(Ci::Pipeline.workflow_rules_failure_message))
          expect(pipeline).not_to be_persisted
        end
      end

      context 'matching no rules in the list' do
        let(:ref) { 'refs/heads/fix' }

        it 'invalidates the pipeline with a workflow rules error' do
          expect(pipeline.errors[:base]).to include(sanitize_message(Ci::Pipeline.workflow_rules_failure_message))
          expect(pipeline).not_to be_persisted
        end
      end
    end

    context 'when root variables are used' do
      let(:config) do
        <<-EOY
          variables:
            VARIABLE: value

          workflow:
            rules:
              - if: $VARIABLE

          regular-job:
            script: 'echo Hello, World!'
        EOY
      end

      context 'matching the first rule in the list' do
        it 'saves a created pipeline' do
          expect(pipeline).to be_created
          expect(pipeline).to be_persisted
        end
      end
    end

    context 'with a multiple regex-matching if: clause' do
      let(:config) do
        <<-EOY
          workflow:
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
              - if: $CI_COMMIT_REF_NAME =~ /^feature/ && $CI_COMMIT_REF_NAME =~ /conflict$/
                when: never
              - if: $CI_COMMIT_REF_NAME =~ /feature/

          regular-job:
            script: 'echo Hello, World!'
        EOY
      end

      context 'with partial match' do
        let(:ref) { 'refs/heads/feature' }

        it 'saves a created pipeline' do
          expect(pipeline).to be_created
          expect(pipeline).to be_persisted
        end
      end

      context 'with complete match' do
        let(:ref) { 'refs/heads/feature_conflict' }

        it 'invalidates the pipeline with a workflow rules error' do
          expect(pipeline.errors[:base]).to include(sanitize_message(Ci::Pipeline.workflow_rules_failure_message))
          expect(pipeline).not_to be_persisted
        end
      end
    end

    context 'with job rules' do
      let(:config) do
        <<-EOY
          workflow:
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
              - if: $CI_COMMIT_REF_NAME =~ /feature/

          regular-job:
            script: 'echo Hello, World!'
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /wip/
              - if: $CI_COMMIT_REF_NAME =~ /feature/
        EOY
      end

      context 'where workflow passes and the job fails' do
        let(:ref) { 'refs/heads/master' }

        it 'invalidates the pipeline with an empty jobs error' do
          expect(pipeline.errors[:base]).to include(sanitize_message(Ci::Pipeline.rules_failure_message))
          expect(pipeline).not_to be_persisted
        end
      end

      context 'where workflow passes and the job passes' do
        let(:ref) { 'refs/heads/feature' }

        it 'saves a created pipeline' do
          expect(pipeline).to be_created
          expect(pipeline).to be_persisted
        end
      end

      context 'where workflow fails and the job fails' do
        let(:ref) { 'refs/heads/fix' }

        it 'invalidates the pipeline with a workflow rules error' do
          expect(pipeline.errors[:base]).to include(sanitize_message(Ci::Pipeline.workflow_rules_failure_message))
          expect(pipeline).not_to be_persisted
        end
      end

      context 'where workflow fails and the job passes' do
        let(:ref) { 'refs/heads/wip' }

        it 'invalidates the pipeline with a workflow rules error' do
          expect(pipeline.errors[:base]).to include(sanitize_message(Ci::Pipeline.workflow_rules_failure_message))
          expect(pipeline).not_to be_persisted
        end
      end
    end

    context 'with persisted variables' do
      let(:config) do
        <<-EOY
          workflow:
            rules:
              - if: $CI_COMMIT_REF_NAME == "master"

          regular-job:
            script: 'echo Hello, World!'
        EOY
      end

      context 'with matches' do
        it 'creates a pipeline' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('regular-job')
        end
      end

      context 'with no matches' do
        let(:ref) { 'refs/heads/feature' }

        it 'does not create a pipeline', :aggregate_failures do
          expect(response).to be_error
          expect(pipeline).not_to be_persisted
        end
      end
    end

    context 'with pipeline variables' do
      let(:initialization_params) { base_initialization_params.merge(variables_attributes: variables_attributes) }

      let(:config) do
        <<-EOY
          workflow:
            rules:
              - if: $SOME_VARIABLE

          regular-job:
            script: 'echo Hello, World!'
        EOY
      end

      context 'with matches' do
        let(:variables_attributes) do
          [{ key: 'SOME_VARIABLE', secret_value: 'SOME_VAR' }]
        end

        it 'creates a pipeline' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('regular-job')
        end
      end

      context 'with no matches' do
        let(:variables_attributes) { {} }

        it 'does not create a pipeline', :aggregate_failures do
          expect(response).to be_error
          expect(pipeline).not_to be_persisted
        end
      end
    end

    context 'with trigger variables' do
      let(:response) do
        service.execute(source) do |pipeline|
          pipeline.variables.build(variables)
        end
      end

      let(:config) do
        <<-EOY
          workflow:
            rules:
              - if: $SOME_VARIABLE

          regular-job:
            script: 'echo Hello, World!'
        EOY
      end

      context 'with matches' do
        let(:variables) do
          [{ key: 'SOME_VARIABLE', secret_value: 'SOME_VAR' }]
        end

        it 'creates a pipeline' do
          expect(pipeline).to be_persisted
          expect(build_names).to contain_exactly('regular-job')
        end

        context 'when a job requires the same variable' do
          let(:config) do
            <<-EOY
              workflow:
                rules:
                  - if: $SOME_VARIABLE

              build:
                stage: build
                script: 'echo build'
                rules:
                  - if: $SOME_VARIABLE

              test1:
                stage: test
                script: 'echo test1'
                needs: [build]

              test2:
                stage: test
                script: 'echo test2'
            EOY
          end

          it 'creates a pipeline' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly('build', 'test1', 'test2')
          end
        end
      end

      context 'with no matches' do
        let(:variables) { {} }

        it 'does not create a pipeline', :aggregate_failures do
          expect(response).to be_error
          expect(pipeline).not_to be_persisted
        end

        context 'when a job requires the same variable' do
          let(:config) do
            <<-EOY
              workflow:
                rules:
                  - if: $SOME_VARIABLE

              build:
                stage: build
                script: 'echo build'
                rules:
                  - if: $SOME_VARIABLE

              test1:
                stage: test
                script: 'echo test1'
                needs: [build]

              test2:
                stage: test
                script: 'echo test2'
            EOY
          end

          it 'does not create a pipeline', :aggregate_failures do
            expect(response).to be_error
            expect(pipeline).not_to be_persisted
          end
        end
      end
    end

    context 'changes' do
      shared_examples 'comparing file changes with workflow rules' do
        context 'when matches' do
          before do
            allow_next_instance_of(Ci::Pipeline) do |pipeline|
              allow(pipeline).to receive(:modified_paths).and_return(%w[file1.md])
            end
          end

          it 'creates the pipeline with a job' do
            expect(pipeline).to be_persisted
            expect(build_names).to contain_exactly('job')
          end
        end

        context 'when does not match' do
          before do
            allow_next_instance_of(Ci::Pipeline) do |pipeline|
              allow(pipeline).to receive(:modified_paths).and_return(%w[unknown])
            end
          end

          it 'creates the pipeline with a job' do
            expect(pipeline.errors.full_messages).to eq([sanitize_message(Ci::Pipeline.workflow_rules_failure_message)])
            expect(response).to be_error
            expect(pipeline).not_to be_persisted
          end
        end
      end

      context 'changes is an array' do
        let(:config) do
          <<-EOY
            workflow:
              rules:
                - changes: [file1.md]

            job:
              script: exit 0
          EOY
        end

        it_behaves_like 'comparing file changes with workflow rules'
      end

      context 'changes:paths is an array' do
        let(:config) do
          <<-EOY
            workflow:
              rules:
                - changes:
                    paths: [file1.md]

            job:
              script: exit 0
          EOY
        end

        it_behaves_like 'comparing file changes with workflow rules'
      end
    end

    context 'workflow name with rules' do
      let(:ref) { 'refs/heads/feature' }

      let(:variables) do
        [{ key: 'SOME_VARIABLE', secret_value: 'SOME_VAL' }]
      end

      let(:response) do
        service.execute(source) do |pipeline|
          pipeline.variables.build(variables)
        end
      end

      let(:config) do
        <<-EOY
          workflow:
            name: '$PIPELINE_NAME $SOME_VARIABLE'
            rules:
              - if: $CI_COMMIT_REF_NAME =~ /master/
                variables:
                  PIPELINE_NAME: 'Name 1'
              - if: $CI_COMMIT_REF_NAME =~ /feature/
                variables:
                  PIPELINE_NAME: 'Name 2'

          job:
            stage: test
            script: echo 'hello'
        EOY
      end

      it 'substitutes variables in pipeline name' do
        expect(response).not_to be_error
        expect(pipeline).to be_persisted
        expect(pipeline.name).to eq('Name 2 SOME_VAL')
      end
    end
  end
end
