# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable RSpec/MultipleMemoizedHelpers -- We need extra helpers to define tables

RSpec.describe Gitlab::BackgroundMigration::MoveCiBuildsMetadata, feature_category: :continuous_integration do
  let(:pipelines_table) { ci_partitioned_table(:p_ci_pipelines) }
  let(:builds_table) do
    ci_partitioned_table(:p_ci_builds).tap do |table|
      table.serialize :options
      table.serialize :yaml_variables
    end
  end

  let(:builds_metadata_table) { ci_partitioned_table(:p_ci_builds_metadata) }
  let(:artifacts_table) { ci_partitioned_table(:p_ci_job_artifacts) }
  let(:tags_table) { ci_partitioned_table(:tags) }
  let(:taggings_table) { ci_partitioned_table(:p_ci_build_tags) }
  let(:execution_configs_table) { ci_partitioned_table(:p_ci_builds_execution_configs) }
  let(:definitions_table) { ci_partitioned_table(:p_ci_job_definitions) }
  let(:definition_instances_table) { table(:p_ci_job_definition_instances, primary_key: :build_id, database: :ci) }

  let(:organizations_table) { table(:organizations, database: :main) }
  let(:namespaces_table) { table(:namespaces, database: :main) }
  let(:projects_table) { table(:projects, database: :main) }
  let(:environments_table) { table(:environments, database: :main) }
  let(:deployments_table) { table(:deployments, database: :main) }
  let(:job_environments_table) { table(:job_environments, database: :main) }

  let(:organization) do
    organizations_table.create!(name: 'organization', path: 'organization')
  end

  let(:namespace) do
    namespaces_table.create!(name: "namespace", path: "namespace", organization_id: organization.id)
  end

  let(:project) do
    projects_table.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:pipeline) { pipelines_table.create!(partition_id: 100, project_id: project.id) }

  let!(:job_a) do
    builds_table.create!(partition_id: pipeline.partition_id, project_id: project.id, commit_id: pipeline.id)
  end

  let!(:job_b) do
    builds_table.create!(partition_id: pipeline.partition_id, project_id: project.id, commit_id: pipeline.id)
  end

  let(:duplicate_configs) do
    {
      config_options: { image: 'ruby', script: 'rspec' },
      config_variables: { 'HOME' => '~' },
      id_tokens: { 'VAULT_ID_TOKEN' => { aud: 'https://gitlab.test' } },
      secrets: { DATABASE_PASSWORD: { vault: 'production/db/password' } },
      interruptible: true
    }
  end

  let!(:metadata_a) do
    builds_metadata_table.create!(
      partition_id: job_a.partition_id, project_id: project.id, build_id: job_a.id, **duplicate_configs
    )
  end

  let!(:metadata_b) do
    builds_metadata_table.create!(
      partition_id: job_b.partition_id, project_id: project.id, build_id: job_b.id, **duplicate_configs
    )
  end

  let(:migration_attrs) do
    {
      start_id: builds_table.minimum(:id),
      end_id: builds_table.maximum(:id),
      batch_table: :p_ci_builds,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection,
      job_arguments: ['partition_id', 100]
    }
  end

  let(:migration) { described_class.new(**migration_attrs) }

  before do
    Ci::ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_job_definitions_100
        PARTITION OF p_ci_job_definitions FOR VALUES IN (100);

      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_job_definition_instances_100
        PARTITION OF p_ci_job_definition_instances FOR VALUES IN (100);
    SQL
  end

  describe '#perform', :aggregate_failures do
    it 'does not raise errors' do
      expect { migration.perform }.not_to raise_error
    end

    it 'creates unique job definitions' do
      expect { migration.perform }
        .to change { definition_instances_table.where(job_id: [job_a.id, job_b.id]).count }.by(2)
        .and change { definitions_table.count }.by(1)

      job_definition = find_definition(job_a)

      expect(job_definition.checksum).to be_present
      expect(job_definition.project_id).to eq(job_a.project_id)
      expect(job_definition.partition_id).to eq(job_a.partition_id)
      expect(job_definition.interruptible).to eq(metadata_a.interruptible)

      expect(job_definition.config).to match({
        'options' => { 'image' => 'ruby', 'script' => 'rspec' },
        'secrets' => { 'DATABASE_PASSWORD' => { 'vault' => 'production/db/password' } },
        'id_tokens' => { 'VAULT_ID_TOKEN' => { 'aud' => 'https://gitlab.test' } },
        'interruptible' => true,
        'yaml_variables' => { 'HOME' => '~' }
      })
    end

    context 'when jobs have id_tokens' do
      let(:duplicate_configs) do
        {
          config_options: { image: 'ruby', script: 'rspec' },
          config_variables: { 'HOME' => '~' },
          id_tokens: { 'VAULT_ID_TOKEN' => { aud: 'https://gitlab.test' } }
        }
      end

      it 'creates unique job definitions' do
        expect { migration.perform }
          .to change { definition_instances_table.where(job_id: [job_a.id, job_b.id]).count }.by(2)
          .and change { definitions_table.count }.by(1)

        job_definition = find_definition(job_a)

        expect(job_definition.checksum).to be_present
        expect(job_definition.project_id).to eq(job_a.project_id)
        expect(job_definition.partition_id).to eq(job_a.partition_id)

        expect(job_definition.config).to match({
          'options' => { 'image' => 'ruby', 'script' => 'rspec' },
          'id_tokens' => { 'VAULT_ID_TOKEN' => { 'aud' => 'https://gitlab.test' } },
          'yaml_variables' => { 'HOME' => '~' }
        })
      end
    end

    context 'when jobs have secrets' do
      let(:duplicate_configs) do
        {
          config_options: { image: 'ruby', script: 'rspec' },
          config_variables: { 'HOME' => '~' },
          secrets: { DATABASE_PASSWORD: { vault: 'production/db/password' } }
        }
      end

      it 'creates unique job definitions' do
        expect { migration.perform }
          .to change { definition_instances_table.where(job_id: [job_a.id, job_b.id]).count }.by(2)
          .and change { definitions_table.count }.by(1)

        job_definition = find_definition(job_a)

        expect(job_definition.checksum).to be_present
        expect(job_definition.project_id).to eq(job_a.project_id)
        expect(job_definition.partition_id).to eq(job_a.partition_id)

        expect(job_definition.config).to match({
          'options' => { 'image' => 'ruby', 'script' => 'rspec' },
          'secrets' => { 'DATABASE_PASSWORD' => { 'vault' => 'production/db/password' } },
          'yaml_variables' => { 'HOME' => '~' }
        })
      end
    end

    context 'when jobs have tags' do
      let(:tag_a) { tags_table.create!(name: 'ruby') }
      let(:tag_b) { tags_table.create!(name: 'rails') }
      let(:tag_c) { tags_table.create!(name: 'postgresql') }
      let(:tag_d) { tags_table.create!(name: 'docker') }

      before do
        taggings_table.insert_all([
          { build_id: job_a.id, partition_id: job_a.partition_id, project_id: job_a.project_id, tag_id: tag_a.id },
          { build_id: job_a.id, partition_id: job_a.partition_id, project_id: job_a.project_id, tag_id: tag_c.id },
          { build_id: job_b.id, partition_id: job_b.partition_id, project_id: job_b.project_id, tag_id: tag_b.id },
          { build_id: job_b.id, partition_id: job_b.partition_id, project_id: job_b.project_id, tag_id: tag_d.id }
        ], unique_by: [:id, :partition_id])
      end

      it 'creates job definitions with tags' do
        expect { migration.perform }.to change { definitions_table.count }.by(2)

        job_definition_a = find_definition(job_a)
        job_definition_b = find_definition(job_b)

        expect(job_definition_a.config['tag_list']).to eq(%w[postgresql ruby])
        expect(job_definition_b.config['tag_list']).to eq(%w[docker rails])
      end
    end

    context 'when jobs have data in p_ci_builds' do
      let(:tag_a) { tags_table.create!(name: 'ruby') }
      let(:tag_b) { tags_table.create!(name: 'rails') }
      let(:tag_c) { tags_table.create!(name: 'postgresql') }
      let(:tag_d) { tags_table.create!(name: 'docker') }

      let(:duplicate_configs) do
        { interruptible: true }
      end

      before do
        taggings_table.insert_all([
          { build_id: job_a.id, partition_id: job_a.partition_id, project_id: job_a.project_id, tag_id: tag_a.id },
          { build_id: job_a.id, partition_id: job_a.partition_id, project_id: job_a.project_id, tag_id: tag_c.id },
          { build_id: job_b.id, partition_id: job_b.partition_id, project_id: job_b.project_id, tag_id: tag_b.id },
          { build_id: job_b.id, partition_id: job_b.partition_id, project_id: job_b.project_id, tag_id: tag_d.id }
        ], unique_by: [:id, :partition_id])

        job_a.update!(
          options: { 'image' => 'ruby', 'script' => 'rspec' },
          yaml_variables: { 'HOME' => '~' }
        )

        job_b.update!(
          options: { 'image' => 'ruby', 'script' => 'rspec' },
          yaml_variables: { 'HOME' => '~', CI: 1 }
        )

        builds_metadata_table.where(build_id: job_b.id).delete_all
      end

      it 'creates job definitions from the builds table' do
        expect { migration.perform }.to change { definitions_table.count }.by(2)

        job_definition_a = find_definition(job_a)
        job_definition_b = find_definition(job_b)

        expect(job_definition_a.config).to match({
          'options' => { 'image' => 'ruby', 'script' => 'rspec' },
          'interruptible' => true,
          'yaml_variables' => { 'HOME' => '~' },
          'tag_list' => %w[postgresql ruby]
        })

        expect(job_definition_b.config).to match({
          'options' => { 'image' => 'ruby', 'script' => 'rspec' },
          'yaml_variables' => { 'HOME' => '~', 'CI' => '1' },
          'tag_list' => %w[docker rails]
        })
      end
    end

    context 'when jobs have execution configs' do
      let(:run_steps) do
        [{ 'name' => 'metrics', 'step' => 'gitlab.com/components/cicd-components/metrics@ref' }]
      end

      let!(:pipeline_a) { pipelines_table.create!(partition_id: 100, project_id: project.id) }
      let!(:pipeline_b) { pipelines_table.create!(partition_id: 100, project_id: project.id) }

      let!(:execution_config_a) do
        execution_configs_table.create!(
          partition_id: pipeline_a.partition_id, project_id: project.id,
          pipeline_id: pipeline_a.id, run_steps: run_steps)
      end

      let!(:execution_config_b) do
        execution_configs_table.create!(
          partition_id: pipeline_b.partition_id, project_id: project.id,
          pipeline_id: pipeline_b.id, run_steps: run_steps)
      end

      let!(:job_a) do
        builds_table.create!(
          partition_id: pipeline_a.partition_id, project_id: project.id,
          commit_id: pipeline_a.id, execution_config_id: execution_config_a.id)
      end

      let!(:job_b) do
        builds_table.create!(
          partition_id: pipeline_b.partition_id, project_id: project.id,
          commit_id: pipeline_b.id, execution_config_id: execution_config_b.id)
      end

      let(:tag_a) { tags_table.create!(name: 'ruby') }
      let(:tag_b) { tags_table.create!(name: 'rails') }

      before do
        taggings_table.insert_all([
          { build_id: job_a.id, partition_id: job_a.partition_id, project_id: job_a.project_id, tag_id: tag_a.id },
          { build_id: job_a.id, partition_id: job_a.partition_id, project_id: job_a.project_id, tag_id: tag_b.id },
          { build_id: job_b.id, partition_id: job_b.partition_id, project_id: job_b.project_id, tag_id: tag_a.id },
          { build_id: job_b.id, partition_id: job_b.partition_id, project_id: job_b.project_id, tag_id: tag_b.id }
        ], unique_by: [:id, :partition_id])
      end

      it 'creates job definitions with tags' do
        expect { migration.perform }.to change { definitions_table.count }.by(1)

        job_definition = find_definition(job_a)

        expect(job_definition.config['tag_list']).to eq(%w[rails ruby])
        expect(job_definition.config['run_steps']).to eq(run_steps)
      end
    end

    context 'if p_ci_builds need to be updated' do
      let!(:job_c) do
        builds_table.create!(
          partition_id: pipeline.partition_id, project_id: project.id, commit_id: pipeline.id,
          timeout: 2800, timeout_source: 2, exit_code: 137,
          debug_trace_enabled: false, scoped_user_id: 10
        )
      end

      let!(:metadata_a) do
        builds_metadata_table.create!(
          partition_id: job_a.partition_id, project_id: project.id, build_id: job_a.id,
          timeout: 3600, timeout_source: 2, exit_code: 0,
          debug_trace_enabled: true, **duplicate_configs
        )
      end

      let!(:metadata_b) do
        builds_metadata_table.create!(
          partition_id: job_b.partition_id, project_id: project.id, build_id: job_b.id,
          timeout: 1800, timeout_source: 1, exit_code: 1,
          debug_trace_enabled: false,
          **duplicate_configs.deep_merge(config_options: { scoped_user_id: 50 })
        )
      end

      let!(:metadata_c) do
        builds_metadata_table.create!(
          partition_id: job_c.partition_id, project_id: project.id, build_id: job_c.id,
          timeout: 1800, timeout_source: 1, exit_code: 0,
          debug_trace_enabled: true,
          **duplicate_configs.deep_merge(config_options: { scoped_user_id: 60 })
        )
      end

      it 'updates jobs from metadata attributes' do
        expect { migration.perform }.not_to raise_error
        [job_a, job_b, job_c].each(&:reload)

        expect(job_a.timeout).to eq(3600)
        expect(job_a.timeout_source).to eq(2)
        expect(job_a.exit_code).to eq(0)
        expect(job_a.debug_trace_enabled).to be(true)
        expect(job_a.scoped_user_id).to be_nil

        expect(job_b.timeout).to eq(1800)
        expect(job_b.timeout_source).to eq(1)
        expect(job_b.exit_code).to eq(1)
        expect(job_b.debug_trace_enabled).to be(false)
        expect(job_b.scoped_user_id).to eq(50)

        expect(job_c.timeout).to eq(2800)
        expect(job_c.timeout_source).to eq(2)
        expect(job_c.exit_code).to eq(137)
        expect(job_c.debug_trace_enabled).to be(false)
        expect(job_c.scoped_user_id).to eq(10)
      end
    end

    context 'if p_ci_job_artifacts need to be updated' do
      let!(:metadata_b) do
        artifacts_options = {
          config_options: {
            artifacts: {
              expose_as: 'string_b',
              paths: ['my/path/b1', 'my/path/b2']
            }
          }
        }

        builds_metadata_table.create!(
          partition_id: job_b.partition_id, project_id: project.id, build_id: job_b.id,
          **duplicate_configs.deep_merge(artifacts_options)
        )
      end

      let!(:job_c) do
        builds_table.create!(partition_id: pipeline.partition_id, project_id: project.id, commit_id: pipeline.id)
      end

      let!(:metadata_c) do
        artifacts_options = {
          config_options: {
            artifacts: {
              expose_as: 'string_c',
              paths: ['my/path/c1', 'my/path/c2']
            }
          }
        }

        builds_metadata_table.create!(
          partition_id: job_c.partition_id, project_id: project.id, build_id: job_c.id,
          **duplicate_configs.deep_merge(artifacts_options)
        )
      end

      let!(:artifact_a) do
        artifacts_table.create!(
          job_id: job_a.id, partition_id: job_a.partition_id,
          project_id: job_a.project_id, file_type: 1
        )
      end

      let!(:artifact_meta_a) do
        artifacts_table.create!(
          job_id: job_a.id, partition_id: job_a.partition_id,
          project_id: job_a.project_id, file_type: 2
        )
      end

      let!(:artifact_b) do
        artifacts_table.create!(
          job_id: job_b.id, partition_id: job_b.partition_id,
          project_id: job_b.project_id, file_type: 1
        )
      end

      let!(:artifact_meta_b) do
        artifacts_table.create!(
          job_id: job_b.id, partition_id: job_b.partition_id,
          project_id: job_b.project_id, file_type: 2
        )
      end

      let!(:artifact_c) do
        artifacts_table.create!(
          job_id: job_c.id, partition_id: job_c.partition_id,
          project_id: job_c.project_id, file_type: 1
        )
      end

      let!(:artifact_meta_c) do
        artifacts_table.create!(
          job_id: job_c.id, partition_id: job_c.partition_id,
          project_id: job_c.project_id, file_type: 2,
          exposed_as: 'artif_string', exposed_paths: ['artif/path/1', 'artif/path/2']
        )
      end

      it 'updates metadata type artifacts from metadata attributes' do
        expect { migration.perform }.not_to raise_error
        [artifact_a, artifact_b, artifact_c, artifact_meta_a, artifact_meta_b, artifact_meta_c].each(&:reload)

        expect(artifact_a.exposed_as).to be_nil
        expect(artifact_a.exposed_paths).to be_nil
        expect(artifact_meta_a.exposed_as).to be_nil
        expect(artifact_meta_a.exposed_paths).to be_nil

        expect(artifact_b.exposed_as).to be_nil
        expect(artifact_b.exposed_paths).to be_nil
        expect(artifact_meta_b.exposed_as).to eq('string_b')
        expect(artifact_meta_b.exposed_paths).to eq(['my/path/b1', 'my/path/b2'])

        expect(artifact_c.exposed_as).to be_nil
        expect(artifact_c.exposed_paths).to be_nil
        expect(artifact_meta_c.exposed_as).to eq('artif_string')
        expect(artifact_meta_c.exposed_paths).to eq(['artif/path/1', 'artif/path/2'])
      end
    end

    context 'if environments need to be moved' do
      let(:namespace_a) do
        namespaces_table.create!(name: "namespace_a", path: "namespace_a", organization_id: organization.id)
      end

      let(:namespace_b) do
        namespaces_table.create!(name: "namespace_b", path: "namespace_b", organization_id: organization.id)
      end

      let!(:project_a) do
        projects_table.create!(
          namespace_id: namespace_a.id,
          project_namespace_id: namespace_a.id,
          organization_id: organization.id
        )
      end

      let!(:project_b) do
        projects_table.create!(
          namespace_id: namespace_b.id,
          project_namespace_id: namespace_b.id,
          organization_id: organization.id
        )
      end

      let!(:staging_a) { environments_table.create!(project_id: project_a.id, name: 'staging_a', slug: 'stg_a') }
      let!(:staging_b) { environments_table.create!(project_id: project_b.id, name: 'staging_b', slug: 'stg_b') }
      let!(:production_a) { environments_table.create!(project_id: project_a.id, name: 'production_a', slug: 'prod_a') }
      let!(:production_b) { environments_table.create!(project_id: project_b.id, name: 'production_b', slug: 'prod_b') }

      let!(:pipeline_a) { pipelines_table.create!(partition_id: 100, project_id: project_a.id) }
      let!(:pipeline_b) { pipelines_table.create!(partition_id: 100, project_id: project_b.id) }

      let!(:job_a) do
        builds_table.create!(partition_id: pipeline_a.partition_id, commit_id: pipeline_a.id, project_id: project_a.id)
      end

      let!(:job_b) do
        builds_table.create!(partition_id: pipeline_b.partition_id, commit_id: pipeline_b.id, project_id: project_b.id)
      end

      let!(:job_c) do
        builds_table.create!(partition_id: pipeline_a.partition_id, commit_id: pipeline_a.id, project_id: project_a.id)
      end

      let!(:job_d) do
        builds_table.create!(partition_id: pipeline_b.partition_id, commit_id: pipeline_b.id, project_id: project_b.id)
      end

      let!(:job_e) do
        builds_table.create!(partition_id: pipeline_a.partition_id, commit_id: pipeline_a.id, project_id: project_a.id)
      end

      let!(:job_f) do
        builds_table.create!(partition_id: pipeline_b.partition_id, commit_id: pipeline_b.id, project_id: project_b.id)
      end

      let!(:job_g) do
        builds_table.create!(partition_id: pipeline_a.partition_id, commit_id: pipeline_a.id, project_id: project_a.id)
      end

      let!(:job_h) do
        builds_table.create!(partition_id: pipeline_b.partition_id, commit_id: pipeline_b.id, project_id: project_b.id)
      end

      let!(:deployment_a) do
        deployments_table.create!(
          project_id: project_a.id, environment_id: staging_a.id, deployable_type: 'CommitStatus',
          deployable_id: job_a.id, iid: 1, ref: 'main', sha: 'aaaaaa', tag: true, status: 0)
      end

      let!(:deployment_b) do
        deployments_table.create!(
          project_id: project_b.id, environment_id: staging_b.id, deployable_id: job_b.id, iid: 1,
          ref: 'main', sha: 'aaaaaa', tag: false, status: 0)
      end

      let!(:deployment_c) do
        deployments_table.create!(
          project_id: project_b.id, environment_id: production_b.id, deployable_type: 'CommitStatus',
          deployable_id: job_d.id, iid: 2, ref: 'main', sha: 'aaaaaa', tag: false, status: 0)
      end

      let!(:metadata_a) do
        environment_name = 'staging_a'
        options = { script: 'example', environment: { name: environment_name } }

        builds_metadata_table.create!(
          partition_id: pipeline_a.partition_id, build_id: job_a.id, project_id: project_a.id,
          expanded_environment_name: environment_name, config_options:  options)
      end

      let!(:metadata_b) do
        environment_name = 'staging_b'
        options = { environment: { name: 'staging_b', action: 'stop', deployment_tier: 'staging' } }

        builds_metadata_table.create!(
          partition_id: pipeline_b.partition_id, build_id: job_b.id, project_id: project_b.id,
          expanded_environment_name: environment_name, config_options: options)
      end

      let!(:metadata_c) do
        environment_name = 'production_a'
        options = { script: 'example', environment: { deployment_tier: 'testing' } }

        builds_metadata_table.create!(
          partition_id: pipeline_a.partition_id, build_id: job_c.id, project_id: project_a.id,
          expanded_environment_name: environment_name, config_options: options)
      end

      let!(:metadata_d) do
        environment_name = 'production_b'
        options = { script: 'example',
                    environment: { name: environment_name, kubernetes: { namespace: 'namespace', agent: 'agent' } } }

        builds_metadata_table.create!(
          partition_id: pipeline_b.partition_id, build_id: job_d.id, project_id: project_b.id,
          expanded_environment_name: environment_name, config_options: options)
      end

      # Skipped: environment name is blank
      let!(:metadata_e) do
        environment_name = nil
        options = { script: 'example', environment: { name: 'excluded' } }

        builds_metadata_table.create!(
          partition_id: pipeline_a.partition_id, build_id: job_e.id, project_id: project_a.id,
          expanded_environment_name: environment_name, config_options: options)
      end

      # Skipped: environment name is present but environment has since been deleted
      let!(:metadata_f) do
        environment_name = 'non-existing'
        options = { script: 'example', environment: { name: 'deleted' } }

        builds_metadata_table.create!(
          partition_id: pipeline_b.partition_id, build_id: job_f.id, project_id: project_b.id,
          expanded_environment_name: environment_name, config_options: options)
      end

      let!(:metadata_g) do
        environment_name = 'staging_a'
        options = nil

        builds_metadata_table.create!(
          partition_id: pipeline_a.partition_id, build_id: job_g.id, project_id: project_a.id,
          expanded_environment_name: environment_name, config_options: options)
      end

      # Skipped: job environment record already exists
      let!(:metadata_h) do
        environment_name = 'staging_b'
        options = { environment: { name: 'staging_b', action: 'stop', deployment_tier: 'staging' } }

        builds_metadata_table.create!(
          partition_id: pipeline_b.partition_id, build_id: job_h.id, project_id: project_b.id,
          expanded_environment_name: environment_name, config_options: options)
      end

      let!(:existing_job_environment) do
        job_environments_table.create!(
          project_id: project_b.id, environment_id: staging_b.id, ci_pipeline_id: pipeline_b.id,
          ci_job_id: job_h.id, expanded_environment_name: staging_b.name,
          options: { action: 'stop', deployment_tier: 'staging' })
      end

      describe '#perform' do
        it 'constructs job_environment records from associated records', :aggregate_failures do
          expect { migration.perform }.to change { job_environments_table.count }.from(1).to(6)

          job_environment_a = job_environments_table.where(ci_job_id: job_a.id).first
          expect(job_environment_a).to have_attributes(
            project_id: project_a.id,
            environment_id: staging_a.id,
            ci_pipeline_id: pipeline_a.id,
            deployment_id: deployment_a.id,
            expanded_environment_name: staging_a.name,
            options: {}
          )

          job_environment_b = job_environments_table.where(ci_job_id: job_b.id).first
          expect(job_environment_b).to have_attributes(
            project_id: project_b.id,
            environment_id: staging_b.id,
            ci_pipeline_id: pipeline_b.id,
            deployment_id: nil,
            expanded_environment_name: staging_b.name,
            options: { 'action' => 'stop', 'deployment_tier' => 'staging' }
          )

          job_environment_c = job_environments_table.where(ci_job_id: job_c.id).first
          expect(job_environment_c).to have_attributes(
            project_id: project_a.id,
            environment_id: production_a.id,
            ci_pipeline_id: pipeline_a.id,
            deployment_id: nil,
            expanded_environment_name: production_a.name,
            options: { 'deployment_tier' => 'testing' }
          )

          job_environment_d = job_environments_table.where(ci_job_id: job_d.id).first
          expect(job_environment_d).to have_attributes(
            project_id: project_b.id,
            environment_id: production_b.id,
            ci_pipeline_id: pipeline_b.id,
            deployment_id: deployment_c.id,
            expanded_environment_name: production_b.name,
            options: { 'kubernetes' => { 'namespace' => 'namespace' } }
          )

          job_environment_e = job_environments_table.where(ci_job_id: job_g.id).first
          expect(job_environment_e).to have_attributes(
            project_id: project_a.id,
            environment_id: staging_a.id,
            ci_pipeline_id: pipeline_a.id,
            deployment_id: nil,
            expanded_environment_name: staging_a.name,
            options: {}
          )
        end
      end
    end

    def find_definition(job)
      instance = definition_instances_table.find_by(job_id: job.id)
      definitions_table.find(instance.job_definition_id)
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
