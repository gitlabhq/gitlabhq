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

  let(:validated_jobs_base) do
    described_class::VALIDATED_JOB_NAMES.index_with { job_config_base }
  end

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
    allow($stdout).to receive(:puts)
  end

  describe '#output_message' do
    shared_examples 'output message' do |warning|
      it 'outputs messages' do
        if warning
          expect(ci_jobs_dependency_validation).to receive(:warn).with(described_class::FAILED_VALIDATION_WARNING)
        else
          expect(ci_jobs_dependency_validation).not_to receive(:warn)
        end

        expect(ci_jobs_dependency_validation.output_message).to eq(expected_message)
      end
    end

    context 'when not in ci environment' do
      let(:ci) { false }
      let(:expected_message) { '' }

      it_behaves_like 'output message'
    end

    context 'when in ci environment' do
      context 'with no ci changes' do
        let(:expected_message) { '' }

        before do
          allow(ci_jobs_dependency_validation.helper).to receive(:has_ci_changes?).and_return(false)
        end

        it_behaves_like 'output message'
      end

      context 'with api fails to retrieve jobs from target branch' do
        let(:error_msg) { '404 not found' }

        before do
          allow(
            ci_jobs_dependency_validation
          ).to receive_message_chain(:gitlab, :api, :get).with("/projects/1/ci/lint", query: {}).and_raise(error_msg)
        end

        it 'warns validation is skipped and outputs empty message' do
          expect(ci_jobs_dependency_validation).to receive(:warn).with(
            "#{described_class::SKIPPED_VALIDATION_WARNING}: #{error_msg}"
          )
          expect { expect(ci_jobs_dependency_validation.output_message).to eq('') }.tap do |expectation|
            expectation
              .to output(<<~MSG).to_stdout
                Initializing 0 jobs from master ci config...
              MSG
          end
        end
      end

      context 'with api fails to retrieve jobs from source branch' do
        let(:error_msg) { '404 not found' }

        before do
          allow(
            ci_jobs_dependency_validation
          ).to receive_message_chain(:gitlab, :api, :get).with("/projects/1/ci/lint", query: query).and_raise(error_msg)
        end

        it 'warns validation is skipped and outputs empty message' do
          expect(ci_jobs_dependency_validation).to receive(:warn).with(
            "#{described_class::SKIPPED_VALIDATION_WARNING}: #{error_msg}"
          )

          expect { expect(ci_jobs_dependency_validation.output_message).to eq('') }.tap do |expectation|
            expectation
              .to output(<<~MSG).to_stdout
                Initializing 1 jobs from master ci config...
                Initializing 0 jobs from feature_branch ci config...
              MSG
          end
        end
      end

      context 'with api returns nil for merged yaml' do
        let(:source_branch_merged_yaml) { nil }

        it 'warns validation is skipped and outputs empty message' do
          expect(ci_jobs_dependency_validation).to receive(:warn).with(
            "#{described_class::SKIPPED_VALIDATION_WARNING}: no implicit conversion of nil into String"
          )

          expect(ci_jobs_dependency_validation.output_message).to eq('')
        end
      end

      context 'when target branch jobs is empty' do
        let(:source_branch_merged_yaml) { YAML.dump({}) }
        let(:expected_message) { '' }

        it_behaves_like 'output message'
      end

      context 'when source branch jobs is empty' do
        let(:master_merged_yaml) { YAML.dump({}) }
        let(:expected_message) { '' }

        it_behaves_like 'output message'
      end

      context 'when jobs do not have dependencies' do
        let(:source_branch_merged_yaml) { YAML.dump(validated_jobs_base) }

        let(:expected_message) { described_class::VALIDATION_PASSED_OUTPUT }

        it_behaves_like 'output message'
      end

      context 'when needed jobs are missing is source branch' do
        let(:source_branch_merged_yaml) do
          YAML.dump({ 'job1' => job_config_base.merge({ 'rules' => rules_with_new_condition }) })
        end

        let(:expected_message) do
          warning_details = described_class::VALIDATED_JOB_NAMES.map do |job_name|
            <<~MARKDOWN
              - :warning: Unable to find job `#{job_name}` in branch `feature_branch`.
                If this job has been removed, please delete it from `Tooling::Danger::CiJobsDependencyValidation::VALIDATED_JOB_NAMES`.
                Validation skipped.
            MARKDOWN
          end.join("\n")

          <<~MARKDOWN.chomp
           ### CI Jobs Dependency Validation

           | name | validation status |
           | ------ | --------------- |
           | `setup-test-env` | :warning: Skipped |
           | `compile-test-assets` | :warning: Skipped |
           | `retrieve-tests-metadata` | :warning: Skipped |
           | `build-gdk-image` | :warning: Skipped |
           | `build-assets-image` | :warning: Skipped |
           | `build-qa-image` | :warning: Skipped |
           | `e2e-test-pipeline-generate` | :warning: Skipped |

           #{warning_details}
          MARKDOWN
        end

        it_behaves_like 'output message', true
      end

      context 'when job1 in branch needs one other job to run' do
        let(:job_name)          { 'job1' }
        let(:needed_job_name)   { 'setup-test-env' }

        let(:source_branch_merged_yaml) do
          YAML.dump(validated_jobs_base.merge(
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
          let(:expected_message) { described_class::VALIDATION_PASSED_OUTPUT }

          it_behaves_like 'output message'
        end

        context 'with a global keyword' do
          let(:job_name) { 'default' }
          let(:expected_message) { described_class::VALIDATION_PASSED_OUTPUT }

          it_behaves_like 'output message'
        end

        context 'when the dependent job config has not changed (identical in master and in branch)' do
          let(:master_merged_yaml) { source_branch_merged_yaml }
          let(:expected_message) { described_class::VALIDATION_PASSED_OUTPUT }

          it_behaves_like 'output message'
        end

        context 'when VALIDATED_JOB_NAMES does not contain the needed job' do
          let(:needed_job_name) { 'not-recognized' }
          let(:expected_message) { described_class::VALIDATION_PASSED_OUTPUT }

          it_behaves_like 'output message'
        end

        context 'when VALIDATED_JOB_NAMES contains the needed job and dependent job config changed' do
          context 'when the added rule is also present in its needed job' do
            let(:source_branch_merged_yaml) do
              YAML.dump(validated_jobs_base.merge({
                job_name => job_config_base.merge({
                  'rules' => rules_with_new_condition,
                  'needs' => [needed_job_name]
                }),
                needed_job_name => { 'rules' => rules_with_new_condition, 'needs' => [] }
              }))
            end

            let(:expected_message) { described_class::VALIDATION_PASSED_OUTPUT }

            it_behaves_like 'output message'
          end

          context 'when an added rule is missing in its needed job' do
            let(:expected_message) do
              <<~MARKDOWN
              ### CI Jobs Dependency Validation

              | name | validation status |
              | ------ | --------------- |
              | `setup-test-env` | 🚨 Failed (1) |
              | `compile-test-assets` | :white_check_mark: Passed |
              | `retrieve-tests-metadata` | :white_check_mark: Passed |
              | `build-gdk-image` | :white_check_mark: Passed |
              | `build-assets-image` | :white_check_mark: Passed |
              | `build-qa-image` | :white_check_mark: Passed |
              | `e2e-test-pipeline-generate` | :white_check_mark: Passed |

              - 🚨 **These rule changes do not match with rules for `setup-test-env`:**

              <details><summary>Click to expand details</summary>

              `job1`:

              - Added rules:

              ```yaml
              - if: $NEW_VAR == "true"
              ```

              - Removed rules:

              `N/A`

              Here are the rules for `setup-test-env`:

              ```yaml
              - if: $CI_MERGE_REQUEST_EVENT_TYPE == "merged_result" || $CI_MERGE_REQUEST_EVENT_TYPE
                  == "detached"
                changes:
                - doc/index.md
              ```

              </details>

              To avoid CI config errors, please verify if the same rule addition/removal should be applied to `setup-test-env`.
              If not, please add a comment to explain why.
              MARKDOWN
            end

            it_behaves_like 'output message', true
          end
        end
      end

      context 'when job configs are malformatted' do
        let(:source_branch_merged_yaml) do
          YAML.dump(validated_jobs_base.merge(
            {
              'job1' => 'not a hash',
              'job2' => ['array'],
              'job3' => { 'key' => 'missing needs and rules' }
            }
          ))
        end

        let(:expected_message) { described_class::VALIDATION_PASSED_OUTPUT }

        it_behaves_like 'output message'
      end

      context 'when dependent job has a rule that is not a hash' do
        let(:source_branch_merged_yaml) do
          YAML.dump(
            validated_jobs_base.merge({
              'job1' => {
                'rules' => ['this is a malformatted rule'],
                'needs' => 'this is a malformatted needs'
              }
            })
          )
        end

        let(:expected_message) { described_class::VALIDATION_PASSED_OUTPUT }

        it_behaves_like 'output message'
      end

      context 'when dependent job have an added rule but condition reads "when: never"' do
        let(:new_condition) { { 'if' => "$NEW_VAR == true", 'when' => 'never' } }
        let(:source_branch_merged_yaml) do
          YAML.dump(
            validated_jobs_base.merge({
              'job1' => {
                'rules' => [new_condition],
                'needs' => ['setup-test-env']
              }
            })
          )
        end

        let(:expected_message) { described_class::VALIDATION_PASSED_OUTPUT }

        it_behaves_like 'output message'
      end

      context 'when dependent job has removed a rule with "when: never"' do
        let(:needed_job_rules) { rules_base }
        let(:master_merged_yaml) do
          YAML.dump(
            validated_jobs_base.merge({
              'job1' => {
                'rules' => [*rules_base, { 'if' => 'true', 'when' => 'never' }],
                'needs' => ['setup-test-env']
              }
            })
          )
        end

        let(:source_branch_merged_yaml) do
          YAML.dump(
            validated_jobs_base.merge({
              'job1' => {
                'rules' => rules_base,
                'needs' => ['setup-test-env']
              },
              'setup-test-env' => {
                'rules' => needed_job_rules
              }
            })
          )
        end

        context 'when needed_job does not have this negative rule' do
          let(:expected_message) { ':white_check_mark: No warnings found in ci job dependencies.' }

          it_behaves_like 'output message'
        end

        context 'when needed_job still has this negative rule' do
          let(:needed_job_rules) { [*rules_base, { 'if' => 'true', 'when' => 'never' }] }
          let(:expected_message) do
            <<~MARKDOWN
              ### CI Jobs Dependency Validation

              | name | validation status |
              | ------ | --------------- |
              | `setup-test-env` | 🚨 Failed (1) |
              | `compile-test-assets` | :white_check_mark: Passed |
              | `retrieve-tests-metadata` | :white_check_mark: Passed |
              | `build-gdk-image` | :white_check_mark: Passed |
              | `build-assets-image` | :white_check_mark: Passed |
              | `build-qa-image` | :white_check_mark: Passed |
              | `e2e-test-pipeline-generate` | :white_check_mark: Passed |

              - 🚨 **These rule changes do not match with rules for `setup-test-env`:**

              <details><summary>Click to expand details</summary>

              `job1`:

              - Added rules:

              `N/A`

              - Removed rules:

              ```yaml
              - if: 'true'
                when: never
              ```

              Here are the rules for `setup-test-env`:

              ```yaml
              - if: $CI_MERGE_REQUEST_EVENT_TYPE == "merged_result" || $CI_MERGE_REQUEST_EVENT_TYPE
                  == "detached"
                changes:
                - doc/index.md
              - if: 'true'
                when: never
              ```

              </details>

              To avoid CI config errors, please verify if the same rule addition/removal should be applied to `setup-test-env`.
              If not, please add a comment to explain why.
            MARKDOWN
          end

          it_behaves_like 'output message', true
        end
      end

      context 'when dependent job have modified rules, but its attributes have nested arrays' do
        let(:source_branch_merged_yaml) do
          YAML.dump(
            validated_jobs_base.merge({
              'job1' => {
                'rules' => [{ 'if' => 'true', 'when' => 'always' }, [new_condition]],
                'needs' => ['setup-test-env', %w[compile-test-assets retrieve-tests-metadata]]
              }
            })
          )
        end

        let(:message_preview) do
          <<~MARKDOWN
            ### CI Jobs Dependency Validation

            | name | validation status |
            | ------ | --------------- |
            | `setup-test-env` | 🚨 Failed (1) |
            | `compile-test-assets` | 🚨 Failed (1) |
            | `retrieve-tests-metadata` | 🚨 Failed (1) |
            | `build-gdk-image` | :white_check_mark: Passed |
            | `build-assets-image` | :white_check_mark: Passed |
            | `build-qa-image` | :white_check_mark: Passed |
            | `e2e-test-pipeline-generate` | :white_check_mark: Passed |

          MARKDOWN
        end

        let(:expected_message) do
          %w[setup-test-env compile-test-assets retrieve-tests-metadata].map do |job_name|
            <<~MARKDOWN
              - 🚨 **These rule changes do not match with rules for `#{job_name}`:**

              <details><summary>Click to expand details</summary>

              `job1`:

              - Added rules:

              ```yaml
              - if: 'true'
                when: always
              - if: $NEW_VAR == "true"
              ```

              - Removed rules:

              `N/A`

              Here are the rules for `#{job_name}`:

              ```yaml
              - if: $CI_MERGE_REQUEST_EVENT_TYPE == "merged_result" || $CI_MERGE_REQUEST_EVENT_TYPE
                  == "detached"
                changes:
                - doc/index.md
              ```

              </details>

              To avoid CI config errors, please verify if the same rule addition/removal should be applied to `#{job_name}`.
              If not, please add a comment to explain why.

            MARKDOWN
          end.join('').prepend(message_preview).chomp
        end

        it_behaves_like 'output message', true
      end
    end
  end

  describe '#fetch_jobs_yaml' do
    context 'with api returns error' do
      before do
        allow(
          ci_jobs_dependency_validation
        ).to receive_message_chain(:gitlab, :api, :get).with("/projects/1/ci/lint", query: {}).and_raise('error')
      end

      it 'returns empty object' do
        expect(ci_jobs_dependency_validation).to receive(:warn).with(
          "#{described_class::SKIPPED_VALIDATION_WARNING}: error"
        )
        expect(ci_jobs_dependency_validation.send(:fetch_jobs_yaml, '1', 'master')).to eq({})
      end
    end

    context 'with returned payload missing merged_yaml' do
      before do
        allow(
          ci_jobs_dependency_validation
        ).to receive_message_chain(:gitlab, :api, :get).with(
          "/projects/1/ci/lint", query: {}
        ).and_return({ 'errors' => ['error'] })
      end

      it 'returns empty object' do
        expect(ci_jobs_dependency_validation).to receive(:warn).with(
          "#{described_class::SKIPPED_VALIDATION_WARNING}: error"
        )
        expect(ci_jobs_dependency_validation.send(:fetch_jobs_yaml, '1', 'master')).to eq({})
      end
    end

    context 'with returned payload has merged_yaml and also has errors' do
      before do
        allow(
          ci_jobs_dependency_validation
        ).to receive_message_chain(:gitlab, :api, :get).with(
          "/projects/1/ci/lint", query: {}
        ).and_return({ 'errors' => ['error'], 'merged_yaml' => master_merged_yaml })
      end

      it 'returns the yaml and disregard the errors' do
        expect(ci_jobs_dependency_validation.send(:fetch_jobs_yaml, '1', 'master')).to eq(
          YAML.load(master_merged_yaml)
        )
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

      it 'returns empty object' do
        expect(ci_jobs_dependency_validation).to receive(:warn).with(
          "#{described_class::SKIPPED_VALIDATION_WARNING}: Tried to load unspecified class: Date"
        )
        expect(ci_jobs_dependency_validation.send(:fetch_jobs_yaml, '1', 'master')).to eq({})
      end
    end
  end
end
