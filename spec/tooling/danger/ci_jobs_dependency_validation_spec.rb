# frozen_string_literal: true

require 'gitlab/dangerfiles/spec_helper'
require 'fast_spec_helper'
require 'webmock/rspec'

require_relative '../../../tooling/danger/ci_jobs_dependency_validation'

RSpec.describe Tooling::Danger::CiJobsDependencyValidation, feature_category: :tooling do
  include_context 'with dangerfile'

  let(:ci) { true }
  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

  let(:rules_base) do
    [
      {
        'if' => '$CI_MERGE_REQUEST_EVENT_TYPE == "merged_result" || $CI_MERGE_REQUEST_EVENT_TYPE == "detached"',
        'changes' => ["doc/index.md"]
      }
    ]
  end

  let(:job_config_base) { { 'rules' => rules_base, 'needs' => [] } }
  let(:new_condition) { { 'if' => '$NEW_VAR == "true"' } }

  let(:rules_with_new_condition) { [*rules_base, new_condition] }

  let(:source_branch_jobs_base) do
    described_class::VALIDATED_JOB_NAMES.index_with { job_config_base }
  end

  let(:source_branch_merged_yaml) { YAML.dump(source_branch_jobs_base) }

  let(:master_merged_yaml) do
    YAML.dump({
      'job1' => job_config_base
    })
  end

  let(:query) do
    {
      content_ref: 'feature_branch',
      dry_run_ref: 'feature_branch',
      include_jobs: true,
      dry_run: true
    }
  end

  subject(:ci_jobs_dependency_validation) { fake_danger.new(helper: fake_helper) }

  before do
    allow(ci_jobs_dependency_validation).to receive_message_chain(:gitlab, :api, :get).with("/projects/1/ci/lint",
      query: {}) do
      { 'merged_yaml' => master_merged_yaml }
    end

    allow(ci_jobs_dependency_validation).to receive_message_chain(:gitlab, :api, :get).with("/projects/1/ci/lint",
      query: query) do
      { 'merged_yaml' => source_branch_merged_yaml }
    end

    allow(ci_jobs_dependency_validation.helper).to receive(:ci?).and_return(ci)
    allow(ci_jobs_dependency_validation.helper).to receive(:has_ci_changes?).and_return(true)
    allow(ci_jobs_dependency_validation.helper).to receive(:mr_source_branch).and_return('feature_branch')
    allow(ci_jobs_dependency_validation.helper).to receive(:mr_target_branch).and_return('master')
    allow(ci_jobs_dependency_validation.helper).to receive(:mr_source_project_id).and_return('1')
    allow(ci_jobs_dependency_validation.helper).to receive(:mr_target_project_id).and_return('1')
  end

  describe '#output_message' do
    shared_examples 'empty message' do |output, num_of_jobs_in_target_branch, num_of_jobs_in_source_branch|
      it 'returns empty string and prints the correct messages to stdout' do
        default_output = <<~OUTPUT
          Initializing #{num_of_jobs_in_target_branch} jobs from master ci config...
          Initializing #{num_of_jobs_in_source_branch} jobs from feature_branch ci config...
          Looking for misconfigured dependent jobs for setup-test-env...
          Detected 0 dependent jobs with misconfigured rules.
          Looking for misconfigured dependent jobs for compile-test-assets...
          Detected 0 dependent jobs with misconfigured rules.
          Looking for misconfigured dependent jobs for retrieve-tests-metadata...
          Detected 0 dependent jobs with misconfigured rules.
          Looking for misconfigured dependent jobs for build-gdk-image...
          Detected 0 dependent jobs with misconfigured rules.
        OUTPUT

        expect { expect(ci_jobs_dependency_validation.output_message).to eq('') }.tap do |expectation|
          expected_output = output == :default_stdout_output ? default_output : output
          expectation.to output(expected_output).to_stdout unless expected_output.nil?
        end
      end
    end

    context 'when not in ci environment' do
      let(:ci) { false }

      it_behaves_like 'empty message', nil
    end

    context 'when in ci environment' do
      context 'with no ci changes' do
        before do
          allow(ci_jobs_dependency_validation.helper).to receive(:has_ci_changes?).and_return(false)
        end

        it_behaves_like 'empty message'
      end

      context 'when target branch jobs is empty' do
        let(:source_branch_merged_yaml) { YAML.dump({}) }

        it_behaves_like 'empty message'
      end

      context 'when retrieving target branch jobs fails' do
        before do
          allow(ci_jobs_dependency_validation).to receive_message_chain(:gitlab, :api, :get)
            .with("/projects/1/ci/lint", query: query).and_raise('404 Not Found')
        end

        it 'prints the failure but does not break' do
          expect { expect(ci_jobs_dependency_validation.output_message).to eq('') }.tap do |expectation|
            expectation
              .to output(<<~MSG).to_stdout
                Initializing 1 jobs from master ci config...
                404 Not Found
                Initializing 0 jobs from feature_branch ci config...
              MSG
          end
        end
      end

      context 'when source branch jobs is empty' do
        let(:master_merged_yaml) { YAML.dump({}) }

        it_behaves_like 'empty message'
      end

      context 'when retrieving source branch jobs fails' do
        before do
          allow(ci_jobs_dependency_validation).to receive_message_chain(:gitlab, :api, :get)
            .with("/projects/1/ci/lint", query: {}).and_raise('404 Not Found')
        end

        it 'prints the failure but does not break' do
          expect { expect(ci_jobs_dependency_validation.output_message).to eq('') }.tap do |expectation|
            expectation
              .to output(<<~MSG).to_stdout
                404 Not Found
                Initializing 0 jobs from master ci config...
              MSG
          end
        end
      end

      context 'when jobs do not have dependencies' do
        it_behaves_like 'empty message', :default_stdout_output, 1, 4
      end

      context 'when needed jobs are missing is source branch' do
        let(:source_branch_merged_yaml) do
          YAML.dump({ 'job1' => job_config_base.merge({ 'rules' => rules_with_new_condition }) })
        end

        it 'returns warning for the missing jobs' do
          expect(ci_jobs_dependency_validation.output_message).to eq(
            <<~MARKDOWN.chomp
              Unable to find job setup-test-env in feature_branch. Skipping.
              Unable to find job compile-test-assets in feature_branch. Skipping.
              Unable to find job retrieve-tests-metadata in feature_branch. Skipping.
              Unable to find job build-gdk-image in feature_branch. Skipping.
            MARKDOWN
          )
        end
      end

      context 'when job1 in branch needs one other job to run' do
        let(:job_name)          { 'job1' }
        let(:needed_job_name)   { 'setup-test-env' }
        let(:needed_job_config) { job_config_base }
        let(:needed_job)        { { needed_job_name => needed_job_config } }

        let(:source_branch_merged_yaml) do
          YAML.dump(source_branch_jobs_base.merge(
            {
              job_name => {
                'rules' => rules_with_new_condition,
                'needs' => [needed_job_name]
              }
            }
          ))
        end

        context 'with a hidden job' do
          let(:job_name) { '.job1' }

          it_behaves_like 'empty message', :default_stdout_output, 1, 5
        end

        context 'with a ignored job' do
          let(:job_name) { 'default' }

          it_behaves_like 'empty message', :default_stdout_output, 1, 5
        end

        context 'when the dependent job config has not changed (identical in master and in branch)' do
          let(:master_merged_yaml) { source_branch_merged_yaml }

          it_behaves_like 'empty message', :default_stdout_output, 5, 5
        end

        context 'when VALIDATED_JOB_NAMES does not contain the needed job' do
          let(:needed_job_name) { 'not-recognized' }

          it_behaves_like 'empty message', :default_stdout_output, 1, 5
        end

        context 'when VALIDATED_JOB_NAMES contains the needed job and dependent job config changed' do
          context 'when the added rule is also present in its needed job' do
            let(:needed_job_config) { job_config_base.merge({ 'rules' => rules_with_new_condition }) }

            it_behaves_like 'empty message'
          end

          context 'when an added rule is missing in its needed job' do
            it 'returns warning' do
              expect(ci_jobs_dependency_validation.output_message).to eq(
                <<~MARKDOWN
                **This MR adds new rules to the following dependent jobs for `setup-test-env`:**

                `job1`:

                ```yaml
                - if: $NEW_VAR == "true"
                ```

                Please ensure the changes are included in the rules for `setup-test-env` to avoid yaml syntax error!

                <details><summary>Click to expand rules for setup-test-env to confirm if the new conditions are present</summary>

                ```yaml
                - if: $CI_MERGE_REQUEST_EVENT_TYPE == "merged_result" || $CI_MERGE_REQUEST_EVENT_TYPE
                    == "detached"
                  changes:
                  - doc/index.md
                ```

                </details>
                MARKDOWN
              )
            end
          end
        end
      end

      context 'when job configs are malformatted' do
        let(:source_branch_merged_yaml) do
          YAML.dump(source_branch_jobs_base.merge(
            {
              'job1' => 'not a hash',
              'job2' => ['array'],
              'job3' => { 'key' => 'missing needs and rules' }
            }
          ))
        end

        it_behaves_like 'empty message', :default_stdout_output, 1, 7
      end

      context 'when dependent job has a rule that is not a hash' do
        let(:source_branch_merged_yaml) do
          YAML.dump(
            source_branch_jobs_base.merge({
              'job1' => {
                'rules' => ['this is a malformatted rule'],
                'needs' => 'this is a malformatted needs'
              }
            })
          )
        end

        it_behaves_like 'empty message', :default_stdout_output, 1, 5
      end

      context 'when dependent job have an added rule but condition reads "when: never"' do
        let(:new_condition) { { 'if' => "$NEW_VAR == true", 'when' => 'never' } }
        let(:source_branch_merged_yaml) do
          YAML.dump(
            source_branch_jobs_base.merge({
              'job1' => {
                'rules' => [new_condition],
                'needs' => ['setup-test-env']
              }
            })
          )
        end

        it_behaves_like 'empty message', <<~OUTPUT
          Initializing 1 jobs from master ci config...
          Initializing 5 jobs from feature_branch ci config...
          Looking for misconfigured dependent jobs for setup-test-env...
          Detected 0 jobs with applicable rule changes.
          Detected 0 dependent jobs with misconfigured rules.
          Looking for misconfigured dependent jobs for compile-test-assets...
          Detected 0 dependent jobs with misconfigured rules.
          Looking for misconfigured dependent jobs for retrieve-tests-metadata...
          Detected 0 dependent jobs with misconfigured rules.
          Looking for misconfigured dependent jobs for build-gdk-image...
          Detected 0 dependent jobs with misconfigured rules.
        OUTPUT
      end

      context 'when dependent job have modified rules, but its attributes has nested arrays' do
        let(:source_branch_merged_yaml) do
          YAML.dump(
            source_branch_jobs_base.merge({
              'job1' => {
                'rules' => [{ 'if' => 'true', 'when' => 'always' }, [new_condition]],
                'needs' => ['setup-test-env', %w[compile-test-assets retrieve-tests-metadata]]
              }
            })
          )
        end

        it 'correctly parses input yaml and returns warning' do
          expected_markdown = %w[setup-test-env compile-test-assets retrieve-tests-metadata].map do |job_name|
            <<~MARKDOWN
            **This MR adds new rules to the following dependent jobs for `#{job_name}`:**

            `job1`:

            ```yaml
            - if: 'true'
              when: always
            - if: $NEW_VAR == "true"
            ```

            Please ensure the changes are included in the rules for `#{job_name}` to avoid yaml syntax error!

            <details><summary>Click to expand rules for #{job_name} to confirm if the new conditions are present</summary>

            ```yaml
            - if: $CI_MERGE_REQUEST_EVENT_TYPE == "merged_result" || $CI_MERGE_REQUEST_EVENT_TYPE
                == "detached"
              changes:
              - doc/index.md
            ```

            </details>

            MARKDOWN
          end.join('').chomp

          expect(ci_jobs_dependency_validation.output_message).to eq(expected_markdown)
        end
      end
    end
  end

  describe '#fetch_jobs_yaml' do
    context 'with api returns error' do
      before do
        allow(
          ci_jobs_dependency_validation
        ).to receive_message_chain(:gitlab, :api, :get).with("/projects/1/ci/lint", query: {}).and_raise('')
      end

      it 'returns jobs yaml' do
        expect(ci_jobs_dependency_validation.send(:fetch_jobs_yaml, '1', 'master')).to eq({})
      end
    end

    context 'with returned payload missing merged_yaml' do
      before do
        allow(
          ci_jobs_dependency_validation
        ).to receive_message_chain(:gitlab, :api, :get).with("/projects/1/ci/lint", query: {}).and_return({})
      end

      it 'returns jobs yaml' do
        expect(ci_jobs_dependency_validation.send(:fetch_jobs_yaml, '1', 'master')).to eq({})
      end
    end

    context 'with returned merged_yaml cannot be parsed' do
      before do
        allow(
          ci_jobs_dependency_validation
        ).to receive_message_chain(:gitlab, :api, :get).with("/projects/1/ci/lint", query: {}).and_return(
          { 'merged_yaml' => 'date: 2024-04-04' }
        )
      end

      it 'returns jobs yaml' do
        expect(ci_jobs_dependency_validation.send(:fetch_jobs_yaml, '1', 'master')).to eq({})
      end
    end
  end
end
