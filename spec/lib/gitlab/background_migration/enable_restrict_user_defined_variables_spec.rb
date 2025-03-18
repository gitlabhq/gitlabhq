# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::EnableRestrictUserDefinedVariables, feature_category: :ci_variables do
  let(:cicd_settings) { table(:project_ci_cd_settings) }
  let!(:org) { table(:organizations).create!(path: 'org') }
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace', organization_id: org.id) }
  let!(:project_1) { create_project('p1') }
  let!(:project_2) { create_project('p2') }
  let!(:project_3) { create_project('p3') }
  let!(:project_4) { create_project('p4') }
  let!(:project_5) { create_project('p5') }
  let!(:project_6) { create_project('p6') }
  let!(:project_7) { create_project('p7') }
  let!(:project_8) { create_project('p8') }

  let(:roles) do
    {
      no_one_allowed: 1,
      developer: 2,
      maintainer: 3,
      owner: 4
    }
  end

  def create_project(name)
    project_namespace = table(:namespaces).create!(name: name, path: name, organization_id: org.id)
    table(:projects).create!(
      name: name,
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: org.id)
  end

  before do
    cicd_settings.create!(
      project_id: project_1.id,
      restrict_user_defined_variables: false,
      pipeline_variables_minimum_override_role: roles.fetch(:developer))
    cicd_settings.create!(
      project_id: project_2.id,
      restrict_user_defined_variables: false,
      pipeline_variables_minimum_override_role: roles.fetch(:maintainer))
    cicd_settings.create!(
      project_id: project_3.id,
      restrict_user_defined_variables: false,
      pipeline_variables_minimum_override_role: roles.fetch(:owner))
    cicd_settings.create!(
      project_id: project_4.id,
      restrict_user_defined_variables: false,
      pipeline_variables_minimum_override_role: roles.fetch(:no_one_allowed))
    cicd_settings.create!(
      project_id: project_5.id,
      restrict_user_defined_variables: true,
      pipeline_variables_minimum_override_role: roles.fetch(:developer))
    cicd_settings.create!(
      project_id: project_6.id,
      restrict_user_defined_variables: true,
      pipeline_variables_minimum_override_role: roles.fetch(:maintainer))
    cicd_settings.create!(
      project_id: project_7.id,
      restrict_user_defined_variables: true,
      pipeline_variables_minimum_override_role: roles.fetch(:owner))
    cicd_settings.create!(
      project_id: project_8.id,
      restrict_user_defined_variables: true,
      pipeline_variables_minimum_override_role: roles.fetch(:no_one_allowed))
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: cicd_settings.minimum(:id),
        end_id: cicd_settings.maximum(:id),
        batch_table: :project_ci_cd_settings,
        batch_column: :id,
        sub_batch_size: 3,
        pause_ms: 0,
        connection: ApplicationRecord.connection)
    end

    it 'updates the settings only when restrict_user_defined_variables: false' do
      expect(cicd_settings.where(restrict_user_defined_variables: false).count).to eq(4)

      migration.perform

      expect(cicd_settings.where(restrict_user_defined_variables: true).count).to eq(cicd_settings.count)

      modified_project_ids = [project_1.id, project_2.id, project_3.id, project_4.id]
      expect(cicd_settings.where(
        project_id: modified_project_ids,
        restrict_user_defined_variables: true,
        pipeline_variables_minimum_override_role: roles.fetch(:developer))
        .count).to eq(modified_project_ids.size)
    end
  end
end
