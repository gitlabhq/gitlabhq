# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigratePagesToZipStorage do
  let(:namespace) { create(:group) } # rubocop: disable RSpec/FactoriesInMigrationSpecs
  let(:migration) { described_class.new }

  describe '#perform' do
    context 'when there is project to migrate' do
      let!(:project) { create_project('project') }

      after do
        FileUtils.rm_rf(project.pages_path)
      end

      it 'migrates project to zip storage' do
        expect_next_instance_of(::Pages::MigrateFromLegacyStorageService,
                                anything,
                                ignore_invalid_entries: false,
                                mark_projects_as_not_deployed: false) do |service|
          expect(service).to receive(:execute_for_batch).with(project.id..project.id).and_call_original
        end

        migration.perform(project.id, project.id)

        expect(project.reload.pages_metadatum.pages_deployment.file.filename).to eq("_migrated.zip")
      end
    end
  end

  def create_project(path)
    project = create(:project) # rubocop: disable RSpec/FactoriesInMigrationSpecs
    project.mark_pages_as_deployed

    FileUtils.mkdir_p File.join(project.pages_path, "public")
    File.open(File.join(project.pages_path, "public/index.html"), "w") do |f|
      f.write("Hello!")
    end

    project
  end
end
