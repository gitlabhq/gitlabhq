# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobDefinition, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:job_definition) { create(:ci_job_definition, project: project) }

  subject { job_definition }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_job_definition, project: project) }
    let!(:parent) { model.project }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    describe 'config validation' do
      subject(:job_definition) { build(:ci_job_definition, project: project, config: config) }

      context 'with valid config' do
        context 'with id_tokens' do
          let(:config) do
            {
              id_tokens: {
                TEST_JWT_TOKEN: {
                  aud: 'https://gitlab.test'
                }
              }
            }
          end

          it { is_expected.to be_valid }
        end

        context 'with interruptible' do
          let(:config) { { interruptible: true } }

          it { is_expected.to be_valid }

          context 'when false' do
            let(:config) { { interruptible: false } }

            it { is_expected.to be_valid }
          end
        end

        context 'with options' do
          let(:config) { { options: { script: ['echo test'] } } }

          it { is_expected.to be_valid }

          context 'for trigger:include::component' do
            let(:config) do
              {
                options: { trigger: {
                  include: [
                    { component: "${CI_SERVER_FQDN}/${CI_PROJECT_PATH}/image-release@${CI_COMMIT_SHA}" }
                  ]
                } }
              }
            end

            it { is_expected.to be_valid }
          end

          context 'for trigger:include::remote' do
            let(:config) do
              {
                options: {
                  trigger: { include: [{ remote: "gitlab-org/gitlab/somefile.yml" }] }
                }
              }
            end

            it { is_expected.to be_valid }
          end

          context 'for trigger:include::rules' do
            let(:config) do
              {
                options: {
                  trigger: { include: [{ ref: "$LIB_REF", file: ["modules/.gitlab-ci.yml"],
                                         rules: [{ if: "$VAR == 'false'" }], project: "gitlab-org/gitlab" }] }
                }
              }
            end

            it { is_expected.to be_valid }
          end

          context 'for trigger:include::template' do
            let(:config) do
              { options: { trigger: { include: [{ template: "Security/Secret-Detection.gitlab-ci.yml" }] } } }
            end

            it { is_expected.to be_valid }
          end

          context 'when trigger:include:inputs contains non-string values' do
            let(:config) do
              {
                options: {
                  trigger: {
                    include: [{ inputs: { quick_deploy: true,
                                          mysql_service: [{ name: "${CI_IMAGE_PREFIX}/mysql:8.0" }],
                                          'configuration-number': 3 } }]
                  }
                }
              }
            end

            it { is_expected.to be_valid }
          end
        end

        context 'with run_steps' do
          let(:config) do
            { run_steps: [{ 'name' => 'step1', 'step' => 'echo', 'inputs' => { 'message' => 'Hello, World!' } }] }
          end

          it { is_expected.to be_valid }
        end

        context 'with secrets' do
          let(:config) do
            { secrets: {
              DATABASE_PASSWORD: {
                vault: {
                  engine: { name: 'kv-v2', path: 'kv-v2' },
                  path: 'production/db',
                  field: 'password'
                }
              }
            } }
          end

          it { is_expected.to be_valid }
        end

        context 'with tag_list' do
          let(:config) { { tag_list: ['build'] } }

          it { is_expected.to be_valid }

          context 'when empty tag_list' do
            let(:config) { { tag_list: [] } }

            it { is_expected.to be_valid }
          end
        end

        context 'with yaml_variables' do
          let(:config) do
            { yaml_variables: [{ key: 'YAML_VARIABLE', value: 'value' }] }
          end

          it { is_expected.to be_valid }
        end
      end

      context 'with invalid config structure' do
        let(:config) { 'invalid' }

        it 'is invalid' do
          expect(Gitlab::AppJsonLogger).to receive(:warn).with(
            class: described_class.name,
            message: 'Invalid config schema detected',
            job_definition_checksum: job_definition.checksum,
            project_id: job_definition.project_id,
            schema_errors: ['value at root is not an object']
          )
          expect(job_definition).not_to be_valid
          expect(job_definition.errors[:config]).to include('value at root is not an object')
        end

        context 'with invalid config properties' do
          let(:config) { { unknown_property: 'random value' } }

          it 'is invalid' do
            expect(Gitlab::AppJsonLogger).to receive(:warn).with(
              class: described_class.name,
              message: 'Invalid config schema detected',
              job_definition_checksum: job_definition.checksum,
              project_id: job_definition.project_id,
              schema_errors: ['object property at `/unknown_property` is a disallowed additional property']
            )
            expect(job_definition).not_to be_valid
            expect(job_definition.errors[:config]).to include(
              'object property at `/unknown_property` is a disallowed additional property')
          end

          context 'when artifacts:reports is null' do
            let(:config) { { options: { artifacts: { reports: nil } } } }

            it 'is invalid' do
              expect(job_definition).not_to be_valid
              expect(job_definition.errors[:config]).to include(
                'value at `/options/artifacts/reports` is not an object')
            end
          end
        end

        context 'with invalid id_tokens' do
          let(:config) { { id_tokens: { TEST_JWT_TOKEN: { id_token: { aud: nil } } } } }

          it 'is invalid' do
            expect(Gitlab::AppJsonLogger).to receive(:warn).with(
              class: described_class.name,
              message: 'Invalid config schema detected',
              job_definition_checksum: job_definition.checksum,
              project_id: job_definition.project_id,
              schema_errors: [
                'object property at `/id_tokens/TEST_JWT_TOKEN/id_token` is a disallowed additional property',
                'object at `/id_tokens/TEST_JWT_TOKEN` is missing required properties: aud'
              ]
            )
            expect(job_definition).not_to be_valid
            expect(job_definition.errors[:config]).to include(
              'object property at `/id_tokens/TEST_JWT_TOKEN/id_token` is a disallowed additional property',
              'object at `/id_tokens/TEST_JWT_TOKEN` is missing required properties: aud')
          end
        end

        context 'with invalid interruptible' do
          let(:config) { { interruptible: {} } }

          it 'is invalid' do
            expect(Gitlab::AppJsonLogger).to receive(:warn).with(
              class: described_class.name,
              message: 'Invalid config schema detected',
              job_definition_checksum: job_definition.checksum,
              project_id: job_definition.project_id,
              schema_errors: ['value at `/interruptible` is not a boolean']
            )
            expect(job_definition).not_to be_valid
            expect(job_definition.errors[:config]).to include(
              'value at `/interruptible` is not a boolean')
          end
        end

        context 'with invalid run_steps' do
          let(:config) { { run_steps: {} } }

          it 'is invalid' do
            expect(Gitlab::AppJsonLogger).to receive(:warn).with(
              class: described_class.name,
              message: 'Invalid config schema detected',
              job_definition_checksum: job_definition.checksum,
              project_id: job_definition.project_id,
              schema_errors: [
                'value at `/run_steps` is not an array'
              ]
            )
            expect(job_definition).not_to be_valid
            expect(job_definition.errors[:config]).to include(
              'value at `/run_steps` is not an array')
          end
        end

        context 'with invalid secrets' do
          let(:config) { { secrets: { DATABASE_PASSWORD: { vault: {} } } } }

          it 'is invalid' do
            expect(Gitlab::AppJsonLogger).to receive(:warn).with(
              class: described_class.name,
              message: 'Invalid config schema detected',
              job_definition_checksum: job_definition.checksum,
              project_id: job_definition.project_id,
              schema_errors: [
                'object at `/secrets/DATABASE_PASSWORD/vault` is missing required properties: path, field, engine'
              ]
            )
            expect(job_definition).not_to be_valid
            expect(job_definition.errors[:config]).to include(
              'object at `/secrets/DATABASE_PASSWORD/vault` is missing required properties: path, field, engine')
          end
        end

        context 'with invalid tag_list' do
          let(:config) { { tag_list: 'one-tag' } }

          it 'is invalid' do
            expect(Gitlab::AppJsonLogger).to receive(:warn).with(
              class: described_class.name,
              message: 'Invalid config schema detected',
              job_definition_checksum: job_definition.checksum,
              project_id: job_definition.project_id,
              schema_errors: [
                'value at `/tag_list` is not an array'
              ]
            )
            expect(job_definition).not_to be_valid
            expect(job_definition.errors[:config]).to include(
              'value at `/tag_list` is not an array')
          end
        end

        context 'with invalid yaml_variables' do
          let(:config) { { yaml_variables: 'invalid' } }

          it 'is invalid' do
            expect(Gitlab::AppJsonLogger).to receive(:warn).with(
              class: described_class.name,
              message: 'Invalid config schema detected',
              job_definition_checksum: job_definition.checksum,
              project_id: job_definition.project_id,
              schema_errors: [
                'value at `/yaml_variables` is not one of the types: ["array", "null"]'
              ]
            )
            expect(job_definition).not_to be_valid
            expect(job_definition.errors[:config]).to include(
              'value at `/yaml_variables` is not one of the types: ["array", "null"]')
          end

          context 'for invalid item' do
            let(:config) { { yaml_variables: [{ key: "RAILS_ENV", unknown_property: true }] } }

            it 'is invalid' do
              expect(Gitlab::AppJsonLogger).to receive(:warn).with(
                class: described_class.name,
                message: 'Invalid config schema detected',
                job_definition_checksum: job_definition.checksum,
                project_id: job_definition.project_id,
                schema_errors: [
                  'object property at `/yaml_variables/0/unknown_property` is a disallowed additional property'
                ]
              )
              expect(job_definition).not_to be_valid
              expect(job_definition.errors[:config]).to include(
                'object property at `/yaml_variables/0/unknown_property` is a disallowed additional property')
            end
          end
        end

        context 'when env is production' do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
          end

          it 'logs the validation errors but behaves like valid' do
            expect(Gitlab::AppJsonLogger).to receive(:warn).with(
              class: described_class.name,
              message: 'Invalid config schema detected',
              job_definition_checksum: job_definition.checksum,
              project_id: job_definition.project_id,
              schema_errors: ['value at root is not an object']
            )
            expect(job_definition).to be_valid
          end

          context 'with invalid config properties' do
            let(:config) { { unknown_property: 'random value' } }

            it 'logs the validation errors but behaves like valid' do
              expect(Gitlab::AppJsonLogger).to receive(:warn).with(
                class: described_class.name,
                message: 'Invalid config schema detected',
                job_definition_checksum: job_definition.checksum,
                project_id: job_definition.project_id,
                schema_errors: ['object property at `/unknown_property` is a disallowed additional property']
              )
              expect(job_definition).to be_valid
            end
          end

          context 'with invalid id_tokens' do
            let(:config) { { id_tokens: { TEST_JWT_TOKEN: { id_token: { aud: nil } } } } }

            it 'logs the validation errors but behaves like valid' do
              expect(Gitlab::AppJsonLogger).to receive(:warn).with(
                class: described_class.name,
                message: 'Invalid config schema detected',
                job_definition_checksum: job_definition.checksum,
                project_id: job_definition.project_id,
                schema_errors: [
                  'object property at `/id_tokens/TEST_JWT_TOKEN/id_token` is a disallowed additional property',
                  'object at `/id_tokens/TEST_JWT_TOKEN` is missing required properties: aud'
                ]
              )
              expect(job_definition).to be_valid
            end
          end

          context 'with invalid interruptible' do
            let(:config) { { interruptible: {} } }

            it 'logs the validation errors but behaves like valid' do
              expect(Gitlab::AppJsonLogger).to receive(:warn).with(
                class: described_class.name,
                message: 'Invalid config schema detected',
                job_definition_checksum: job_definition.checksum,
                project_id: job_definition.project_id,
                schema_errors: ['value at `/interruptible` is not a boolean']
              )
              expect(job_definition).to be_valid
            end
          end

          context 'with invalid run_steps' do
            let(:config) { { run_steps: {} } }

            it 'logs the validation errors but behaves like valid' do
              expect(Gitlab::AppJsonLogger).to receive(:warn).with(
                class: described_class.name,
                message: 'Invalid config schema detected',
                job_definition_checksum: job_definition.checksum,
                project_id: job_definition.project_id,
                schema_errors: [
                  'value at `/run_steps` is not an array'
                ]
              )
              expect(job_definition).to be_valid
            end
          end

          context 'with invalid secrets' do
            let(:config) { { secrets: { DATABASE_PASSWORD: { vault: {} } } } }

            it 'logs the validation errors but behaves like valid' do
              expect(Gitlab::AppJsonLogger).to receive(:warn).with(
                class: described_class.name,
                message: 'Invalid config schema detected',
                job_definition_checksum: job_definition.checksum,
                project_id: job_definition.project_id,
                schema_errors: [
                  'object at `/secrets/DATABASE_PASSWORD/vault` is missing required properties: path, field, engine'
                ]
              )
              expect(job_definition).to be_valid
            end
          end

          context 'with invalid tag_list' do
            let(:config) { { tag_list: 'one-tag' } }

            it 'logs the validation errors but behaves like valid' do
              expect(Gitlab::AppJsonLogger).to receive(:warn).with(
                class: described_class.name,
                message: 'Invalid config schema detected',
                job_definition_checksum: job_definition.checksum,
                project_id: job_definition.project_id,
                schema_errors: [
                  'value at `/tag_list` is not an array'
                ]
              )
              expect(job_definition).to be_valid
            end
          end

          context 'with invalid yaml_variables' do
            let(:config) { { yaml_variables: 'invalid' } }

            it 'logs the validation errors but behaves like valid' do
              expect(Gitlab::AppJsonLogger).to receive(:warn).with(
                class: described_class.name,
                message: 'Invalid config schema detected',
                job_definition_checksum: job_definition.checksum,
                project_id: job_definition.project_id,
                schema_errors: [
                  'value at `/yaml_variables` is not one of the types: ["array", "null"]'
                ]
              )
              expect(job_definition).to be_valid
            end

            context 'for invalid item' do
              let(:config) { { yaml_variables: [{ key: "RAILS_ENV", unknown_property: true }] } }

              it 'logs the validation errors but behaves like valid' do
                expect(Gitlab::AppJsonLogger).to receive(:warn).with(
                  class: described_class.name,
                  message: 'Invalid config schema detected',
                  job_definition_checksum: job_definition.checksum,
                  project_id: job_definition.project_id,
                  schema_errors: [
                    'object property at `/yaml_variables/0/unknown_property` is a disallowed additional property'
                  ]
                )
                expect(job_definition).to be_valid
              end
            end
          end
        end
      end
    end
  end

  describe 'constants' do
    describe 'CONFIG_ATTRIBUTES' do
      it 'defines the correct attributes in order' do
        expect(described_class::CONFIG_ATTRIBUTES).to eq([
          :options,
          :yaml_variables,
          :id_tokens,
          :secrets,
          :interruptible,
          :tag_list,
          :run_steps
        ])
      end
    end
  end

  describe 'read only' do
    let(:new_config_value) { { options: { script: 'new script' } } }

    it 'does not allow a persisted record to be updated', :aggregate_failures do
      job_definition.config = new_config_value
      expect { job_definition.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)

      expect { job_definition.update!(config: new_config_value) }
        .to raise_error(ActiveRecord::ReadOnlyRecord)

      expect { job_definition.update_column(:config, new_config_value) }
        .to raise_error(ActiveRecord::ReadOnlyRecord)

      expect { job_definition.update_columns(config: new_config_value) }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe '.use_new_checksum_approach?' do
    subject { described_class.use_new_checksum_approach?(project.id, partition_id) }

    before do
      stub_feature_flags(ci_job_definitions_force_new_checksum: false)
    end

    context 'with partition_id below threshold' do
      let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD - 1 }

      it { is_expected.to be false }
    end

    context 'with partition_id at threshold' do
      let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD }

      it { is_expected.to be true }
    end

    context 'with partition_id above threshold' do
      let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD + 1 }

      it { is_expected.to be true }
    end

    context 'when partition_id is missing but a current ci_partitions record exists' do
      let(:partition_id) { nil }

      before do
        create(:ci_partition, :current)
      end

      it { is_expected.to be false }
    end

    context 'when partition_id is missing and no ci_partitions records exist' do
      let(:partition_id) { nil }

      it { is_expected.to be false }
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(ci_job_definitions_new_checksum: false)
      end

      context 'with partition_id below threshold' do
        let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD - 1 }

        it { is_expected.to be false }
      end

      context 'with partition_id at threshold' do
        let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD }

        it { is_expected.to be false }
      end

      context 'with partition_id above threshold' do
        let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD + 1 }

        it { is_expected.to be false }
      end
    end

    context 'when override feature flag is enabled' do
      before do
        stub_feature_flags(ci_job_definitions_force_new_checksum: true)
      end

      context 'with partition_id below threshold' do
        let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD - 1 }

        it { is_expected.to be true }
      end

      context 'with partition_id at threshold' do
        let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD }

        it { is_expected.to be true }
      end

      context 'with partition_id above threshold' do
        let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD + 1 }

        it { is_expected.to be true }
      end
    end
  end

  describe '.fabricate' do
    let(:config) do
      {
        options: { script: ['echo test'] },
        yaml_variables: [{ key: 'VAR', value: 'value' }],
        interruptible: true,
        extra_field: 'should be ignored'
      }
    end

    let(:project_id) { project.id }
    let(:partition_id) { 100 }

    subject(:fabricate) do
      described_class.fabricate(config: config, project_id: project_id, partition_id: partition_id)
    end

    it 'sets the correct attributes' do
      expect(fabricate).to have_attributes(
        project_id: project_id,
        partition_id: partition_id,
        interruptible: true
      )
    end

    it 'sanitizes the config' do
      expect(fabricate.config).to eq(
        options: { script: ['echo test'] },
        yaml_variables: [{ key: 'VAR', value: 'value' }]
      )
      # Normalized data column is stored separately
      expect(fabricate.interruptible).to be true
    end

    it 'generates a checksum' do
      expect(fabricate.checksum).to be_present
      expect(fabricate.checksum).to match(/\A[a-f0-9]{64}\z/)
    end

    it 'sets created_at', :freeze_time do
      expect(fabricate.created_at).to eq(Time.current)
    end

    context 'with interruptible not specified' do
      let(:config) { { options: { script: ['echo test'] } } }

      it 'uses column default for interruptible' do
        expect(fabricate.interruptible).to eq(described_class.column_defaults['interruptible'])
      end
    end

    context "when the partition_id is greater than or equal to #{described_class::NEW_CHECKSUM_PARTITION_THRESHOLD}" do
      let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD }

      before do
        stub_feature_flags(ci_job_definitions_force_new_checksum: false)
      end

      context 'when interruptible is not specified' do
        let(:config) { { options: { script: ['echo test'] } } }
        let(:old_fabricate) do
          described_class.fabricate(config: config, project_id: project_id, partition_id: partition_id - 1)
        end

        it 'does not include normalized data columns in persisted config' do
          expect(fabricate.config).not_to have_key(:interruptible)
        end

        it 'sets normalized data column attribute' do
          expect(fabricate.interruptible).to eq(described_class.column_defaults['interruptible'])
        end

        it 'generates different checksum than old approach' do
          expect(old_fabricate.checksum).not_to eq(fabricate.checksum)
        end
      end

      context 'when interruptible is explicitly set' do
        let(:config) { { options: { script: ['echo test'] }, interruptible: true } }

        it 'does not include normalized data columns in persisted config' do
          expect(fabricate.config).not_to have_key(:interruptible)
        end

        it 'sets normalized data column attribute' do
          expect(fabricate.interruptible).to be true
        end
      end
    end

    context "when the partition_id is less than #{described_class::NEW_CHECKSUM_PARTITION_THRESHOLD}" do
      let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD - 1 }

      before do
        stub_feature_flags(ci_job_definitions_force_new_checksum: false)
      end

      context 'when interruptible is not specified' do
        let(:config) { { options: { script: ['echo test'] } } }

        it 'does not include normalized data columns in persisted config' do
          expect(fabricate.config).not_to have_key(:interruptible)
        end

        it 'sets normalized data column attribute with default value' do
          expect(fabricate.interruptible).to eq(described_class.column_defaults['interruptible'])
        end
      end

      context 'when interruptible is explicitly set' do
        let(:config) { { options: { script: ['echo test'] }, interruptible: true } }

        it 'includes normalized data columns in persisted config when explicitly passed' do
          expect(fabricate.config[:interruptible]).to be true
        end

        it 'sets normalized data column attribute' do
          expect(fabricate.interruptible).to be true
        end
      end

      context 'when the force flag is enabled' do
        before do
          stub_feature_flags(ci_job_definitions_force_new_checksum: true)
        end

        context 'when interruptible is not specified' do
          let(:config) { { options: { script: ['echo test'] } } }

          it 'does not include normalized data columns in persisted config' do
            expect(fabricate.config).not_to have_key(:interruptible)
          end

          it 'sets normalized data column attribute' do
            expect(fabricate.interruptible).to eq(described_class.column_defaults['interruptible'])
          end
        end

        context 'when interruptible is explicitly set' do
          let(:config) { { options: { script: ['echo test'] }, interruptible: true } }

          it 'does not include normalized data columns in persisted config' do
            expect(fabricate.config).not_to have_key(:interruptible)
          end

          it 'sets normalized data column attribute' do
            expect(fabricate.interruptible).to be true
          end
        end
      end
    end

    context 'when the feature flags are disabled' do
      let(:partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD }
      let(:old_partition_id) { described_class::NEW_CHECKSUM_PARTITION_THRESHOLD - 1 }

      before do
        stub_feature_flags(
          ci_job_definitions_new_checksum: false,
          ci_job_definitions_force_new_checksum: false
        )
      end

      context 'when interruptible is not specified' do
        let(:config) { { options: { script: ['echo test'] } } }
        let(:old_fabricate) do
          described_class.fabricate(config: config, project_id: project_id, partition_id: old_partition_id)
        end

        it 'uses old checksum approach even with partition at threshold' do
          expect(fabricate.config).not_to have_key(:interruptible)
          expect(fabricate.interruptible).to eq(described_class.column_defaults['interruptible'])
        end

        it 'does not include normalized data columns in persisted config when not explicitly passed' do
          expect(fabricate.config).not_to have_key(:interruptible)
        end

        it 'generates same checksum as old approach' do
          expect(fabricate.checksum).to eq(old_fabricate.checksum)
        end
      end
    end

    context 'with tag_list' do
      using RSpec::Parameterized::TableSyntax

      where(:input_tags, :expected_tags) do
        ['build']                      | ['build']
        ['TAG1,TAG2']                  | %w[TAG1 TAG2]
        %w[TAG1,TAG2 TAG3]             | %w[TAG1 TAG2 TAG3]
        ['  TAG1,TAG2  ', '   TAG3  '] | %w[TAG1 TAG2 TAG3]
        %w[TAG1 TAG2 TAG1]             | %w[TAG1 TAG2]
        %w[TAG3 TAG1,TAG2]             | %w[TAG3 TAG1 TAG2]
      end

      with_them do
        let(:config) do
          {
            options: { script: ['echo test'] },
            tag_list: input_tags,
            extra_field: 'should be ignored'
          }
        end

        it 'parses and normalizes tags correctly' do
          expect(fabricate.config[:tag_list]).to eq(expected_tags)
        end
      end
    end

    context 'with all CONFIG_ATTRIBUTES specified' do
      let(:config) do
        {
          options: { script: ['echo test'] },
          yaml_variables: [{ key: 'VAR', value: 'value' }],
          id_tokens: { TEST_TOKEN: { aud: 'https://gitlab.com' } },
          secrets: { TEST_SECRET: { gitlab_secrets_manager: { name: 'foo' } } },
          interruptible: true, tag_list: %w[ruby postgresql],
          run_steps: [{ 'name' => 'step1', 'step' => 'echo', 'inputs' => { 'message' => 'Hello, World!' } }]
        }
      end

      it 'includes all specified CONFIG_ATTRIBUTES except normalized data columns' do
        expect(fabricate.config.keys).to match_array(
          described_class::CONFIG_ATTRIBUTES - described_class::NORMALIZED_DATA_COLUMNS
        )
        expect(fabricate.interruptible).to be true
      end

      context 'when FF `ci_job_definitions_new_checksum` is disabled' do
        before do
          stub_feature_flags(ci_job_definitions_new_checksum: false)
        end

        it 'includes all specified CONFIG_ATTRIBUTES' do
          expect(fabricate.config.keys).to match_array(described_class::CONFIG_ATTRIBUTES)
          expect(fabricate.interruptible).to be true
        end
      end
    end
  end

  describe '#tag_list' do
    using RSpec::Parameterized::TableSyntax

    subject(:tag_list) { job_definition.tag_list }

    where(:config_tags, :expected_tags, :description) do
      ['tag1,tag2']       | %w[tag1 tag2]      | 'comma-delimited string in array'
      ['tag1, tag2']      | %w[tag1 tag2]      | 'comma-delimited string with spaces'
      %w[tag1 tag2]       | %w[tag1 tag2]      | 'array of strings'
      ['']                | []                 | 'empty string in array'
      []                  | []                 | 'empty array'
      ['  tag1  , tag2 '] | %w[tag1 tag2]      | 'string with extra whitespace'
      %w[tag1 tag2 tag1]  | %w[tag1 tag2]      | 'duplicate tags are removed'
    end

    with_them do
      let(:job_definition) do
        create(:ci_job_definition, project: project, config: { tag_list: config_tags })
      end

      it 'parses tags correctly' do
        is_expected.to match_array(expected_tags)
      end
    end

    context 'when tag_list is not present in config' do
      let(:job_definition) do
        create(:ci_job_definition, project: project, config: { options: { script: ['echo test'] } })
      end

      it { is_expected.to eq([]) }
    end
  end

  describe '.sanitize_config' do
    let(:config) do
      {
        options: { script: ['echo test'] },
        yaml_variables: [{ key: 'VAR', value: 'value' }],
        id_tokens: { TEST_TOKEN: { aud: 'https://gitlab.com' } },
        secrets: { TEST_SECRET: { gitlab_secrets_manager: { name: 'foo' } } },
        interruptible: true,
        extra_field: 'should be ignored'
      }
    end

    subject(:result) { described_class.sanitize_config(config) }

    it 'returns a sanitized config hash' do
      expect(result).to be_a(Hash)
    end

    it 'includes only CONFIG_ATTRIBUTES that were present in input' do
      expect(result.keys).to contain_exactly(:options, :yaml_variables, :id_tokens, :secrets, :interruptible)
      expect(result).not_to have_key(:extra_field)
    end

    it 'symbolizes keys in the result' do
      string_key_config = { 'options' => { 'script' => ['echo test'] } }
      sanitized_config = described_class.sanitize_config(string_key_config)

      expect(sanitized_config).to have_key(:options)
      expect(sanitized_config).not_to have_key('options')
    end

    context 'with tag_list' do
      let(:config) do
        {
          options: { script: ['echo test'] },
          tag_list: %w[tag1,tag2 tag3]
        }
      end

      it 'parses and normalizes tags' do
        expect(result[:tag_list]).to eq(%w[tag1 tag2 tag3])
      end
    end
  end

  describe '.generate_checksum' do
    let(:config) do
      {
        options: { script: ['echo test'] },
        yaml_variables: [{ key: 'VAR', value: 'value' }],
        interruptible: true
      }
    end

    subject(:checksum) { described_class.generate_checksum(config) }

    it 'returns a checksum string' do
      expect(checksum).to be_a(String)
    end

    it 'uses SHA256 for checksum' do
      is_expected.to match(/\A[a-f0-9]{64}\z/)
    end

    it 'generates consistent checksum for same data' do
      checksum1 = described_class.generate_checksum(config)
      checksum2 = described_class.generate_checksum(config)

      expect(checksum1).to eq(checksum2)
    end

    it 'generates different checksums for different data' do
      config2 = config.merge(options: { script: ['echo different'] })

      checksum1 = described_class.generate_checksum(config)
      checksum2 = described_class.generate_checksum(config2)

      expect(checksum1).not_to eq(checksum2)
    end

    it 'generates different checksums for different key order' do
      # Create two configs with same data but different key order
      config1 = {
        interruptible: true,
        options: { script: ['test'] },
        yaml_variables: [{ key: 'VAR', value: 'val' }]
      }

      config2 = {
        yaml_variables: [{ key: 'VAR', value: 'val' }],
        options: { script: ['test'] },
        interruptible: true
      }

      checksum1 = described_class.generate_checksum(config1)
      checksum2 = described_class.generate_checksum(config2)

      # JSON serialization preserves insertion order, so different key orders produce different checksums
      expect(checksum1).not_to eq(checksum2)
    end
  end
end
