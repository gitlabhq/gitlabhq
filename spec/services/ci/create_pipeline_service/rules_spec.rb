# frozen_string_literal: true
require 'spec_helper'

describe Ci::CreatePipelineService do
  let(:user)        { create(:admin) }
  let(:ref)         { 'refs/heads/master' }
  let(:source)      { :push }
  let(:project)     { create(:project, :repository) }
  let(:service)     { described_class.new(project, user, { ref: ref }) }
  let(:pipeline)    { service.execute(source) }
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
  end

  context 'when workflow:rules are used' do
    before do
      stub_ci_pipeline_yaml_file(config)
    end

    shared_examples 'workflow:rules feature disabled' do
      before do
        stub_feature_flags(workflow_rules: false)
      end

      it 'presents a message that rules are disabled' do
        expect(pipeline.errors[:base]).to include('Workflow rules are disabled')
        expect(pipeline).to be_persisted
      end
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
        it 'saves a pending pipeline' do
          expect(pipeline).to be_pending
          expect(pipeline).to be_persisted
        end
      end

      context 'matching the last rule in the list' do
        let(:ref) { 'refs/heads/feature' }

        it 'saves a pending pipeline' do
          expect(pipeline).to be_pending
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
        it 'saves a pending pipeline' do
          expect(pipeline).to be_pending
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

        it 'saves a pending pipeline' do
          expect(pipeline).to be_pending
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

        it_behaves_like 'workflow:rules feature disabled'
      end

      context 'where workflow passes and the job passes' do
        let(:ref) { 'refs/heads/feature' }

        it 'saves a pending pipeline' do
          expect(pipeline).to be_pending
          expect(pipeline).to be_persisted
        end

        it_behaves_like 'workflow:rules feature disabled'
      end

      context 'where workflow fails and the job fails' do
        let(:ref) { 'refs/heads/fix' }

        it 'invalidates the pipeline with a workflow rules error' do
          expect(pipeline.errors[:base]).to include('Pipeline filtered out by workflow rules.')
          expect(pipeline).not_to be_persisted
        end

        it_behaves_like 'workflow:rules feature disabled'
      end

      context 'where workflow fails and the job passes' do
        let(:ref) { 'refs/heads/wip' }

        it 'invalidates the pipeline with a workflow rules error' do
          expect(pipeline.errors[:base]).to include('Pipeline filtered out by workflow rules.')
          expect(pipeline).not_to be_persisted
        end

        it_behaves_like 'workflow:rules feature disabled'
      end
    end
  end
end
