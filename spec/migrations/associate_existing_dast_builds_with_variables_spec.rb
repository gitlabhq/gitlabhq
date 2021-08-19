# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20210629031900_associate_existing_dast_builds_with_variables.rb')

RSpec.describe AssociateExistingDastBuildsWithVariables do
  subject(:migration) { described_class.new }

  let_it_be(:namespaces_table) { table(:namespaces) }
  let_it_be(:projects_table) { table(:projects) }
  let_it_be(:ci_pipelines_table) { table(:ci_pipelines) }
  let_it_be(:ci_builds_table) { table(:ci_builds) }
  let_it_be(:dast_sites_table) { table(:dast_sites) }
  let_it_be(:dast_site_profiles_table) { table(:dast_site_profiles) }
  let_it_be(:dast_scanner_profiles_table) { table(:dast_scanner_profiles) }
  let_it_be(:dast_site_profiles_builds_table) { table(:dast_site_profiles_builds) }
  let_it_be(:dast_profiles_table) { table(:dast_profiles) }
  let_it_be(:dast_profiles_pipelines_table) { table(:dast_profiles_pipelines) }

  let!(:group) { namespaces_table.create!(type: 'Group', name: 'group', path: 'group') }
  let!(:project) { projects_table.create!(name: 'project', path: 'project', namespace_id: group.id) }

  let!(:pipeline_0) { ci_pipelines_table.create!(project_id: project.id, source: 13) }
  let!(:pipeline_1) { ci_pipelines_table.create!(project_id: project.id, source: 13) }
  let!(:build_0) { ci_builds_table.create!(project_id: project.id, commit_id: pipeline_0.id, name: :dast, stage: :dast) }
  let!(:build_1) { ci_builds_table.create!(project_id: project.id, commit_id: pipeline_0.id, name: :dast, stage: :dast) }
  let!(:build_2) { ci_builds_table.create!(project_id: project.id, commit_id: pipeline_1.id, name: :dast, stage: :dast) }
  let!(:build_3) { ci_builds_table.create!(project_id: project.id, commit_id: pipeline_1.id, name: :dast) }
  let!(:build_4) { ci_builds_table.create!(project_id: project.id, commit_id: pipeline_1.id, stage: :dast) }

  let!(:dast_site) { dast_sites_table.create!(project_id: project.id, url: generate(:url)) }
  let!(:dast_site_profile) { dast_site_profiles_table.create!(project_id: project.id, dast_site_id: dast_site.id, name: SecureRandom.hex) }
  let!(:dast_scanner_profile) { dast_scanner_profiles_table.create!(project_id: project.id, name: SecureRandom.hex) }

  let!(:dast_profile) do
    dast_profiles_table.create!(
      project_id: project.id,
      dast_site_profile_id: dast_site_profile.id,
      dast_scanner_profile_id: dast_scanner_profile.id,
      name: SecureRandom.hex,
      description: SecureRandom.hex
    )
  end

  let!(:dast_profiles_pipeline_0) { dast_profiles_pipelines_table.create!(dast_profile_id: dast_profile.id, ci_pipeline_id: pipeline_0.id) }
  let!(:dast_profiles_pipeline_1) { dast_profiles_pipelines_table.create!(dast_profile_id: dast_profile.id, ci_pipeline_id: pipeline_1.id) }

  context 'when there are ci_pipelines with associated dast_profiles' do
    describe 'migration up' do
      it 'adds association of dast_site_profiles to ci_builds', :aggregate_failures do
        expect(dast_site_profiles_builds_table.all).to be_empty

        migration.up

        expected_results = [
          [dast_site_profile.id, build_0.id],
          [dast_site_profile.id, build_1.id],
          [dast_site_profile.id, build_2.id]
        ]

        expect(dast_site_profiles_builds_table.all.map { |assoc| [assoc.dast_site_profile_id, assoc.ci_build_id] }).to contain_exactly(*expected_results)
      end
    end
  end

  describe 'migration down' do
    it 'deletes all records in the dast_site_profiles_builds table', :aggregate_failures do
      expect(dast_site_profiles_builds_table.all).to be_empty

      migration.up
      migration.down

      expect(dast_site_profiles_builds_table.all).to be_empty
    end
  end
end
