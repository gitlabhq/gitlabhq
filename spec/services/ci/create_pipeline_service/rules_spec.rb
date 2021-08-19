# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  let(:project)     { create(:project, :repository) }
  let(:user)        { project.owner }
  let(:ref)         { 'refs/heads/master' }
  let(:source)      { :push }
  let(:service)     { described_class.new(project, user, { ref: ref }) }
  let(:pipeline)    { service.execute(source).payload }
  let(:build_names) { pipeline.builds.pluck(:name) }

  context 'job:rules' do
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

    context 'with allow_failure and exit_codes', :aggregate_failures do
      def find_job(name)
        pipeline.builds.find_by(name: name)
      end

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
        expect(find_job('job-1').options.dig(:allow_failure_criteria)).to be_nil
        expect(find_job('job-2').options.dig(:allow_failure_criteria)).to be_nil
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

        let(:variable_keys) { %w(VAR1 VAR2 VAR3 VAR4 VAR5 VAR6 VAR7) }

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
          expect(pipeline.errors[:base]).to include('Pipeline filtered out by workflow rules.')
          expect(pipeline).not_to be_persisted
        end
      end

      context 'matching no rules in the list' do
        let(:ref) { 'refs/heads/fix' }

        it 'invalidates the pipeline with a workflow rules error' do
          expect(pipeline.errors[:base]).to include('Pipeline filtered out by workflow rules.')
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
          expect(pipeline.errors[:base]).to include('Pipeline filtered out by workflow rules.')
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
          expect(pipeline.errors[:base]).to include('No stages / jobs for this pipeline.')
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
          expect(pipeline.errors[:base]).to include('Pipeline filtered out by workflow rules.')
          expect(pipeline).not_to be_persisted
        end
      end

      context 'where workflow fails and the job passes' do
        let(:ref) { 'refs/heads/wip' }

        it 'invalidates the pipeline with a workflow rules error' do
          expect(pipeline.errors[:base]).to include('Pipeline filtered out by workflow rules.')
          expect(pipeline).not_to be_persisted
        end
      end
    end
  end
end
