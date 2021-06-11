# frozen_string_literal: true

# This spec is a lightweight version of:
#   * project/tree_restorer_spec.rb
#
# In depth testing is being done in the above specs.
# This spec tests that restore project works
# but does not have 100% relation coverage.

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::RelationTreeRestorer do
  include_context 'relation tree restorer shared context'

  let(:relation_tree_restorer) do
    described_class.new(
      user:                  user,
      shared:                shared,
      relation_reader:       relation_reader,
      object_builder:        object_builder,
      members_mapper:        members_mapper,
      relation_factory:      relation_factory,
      reader:                reader,
      importable:            importable,
      importable_path:       importable_path,
      importable_attributes: attributes
    )
  end

  subject { relation_tree_restorer.restore }

  shared_examples 'import project successfully' do
    it 'restores project tree' do
      expect(subject).to eq(true)
    end

    describe 'imported project' do
      let(:project) { Project.find_by_path('project') }

      before do
        subject
      end

      it 'has the project attributes and relations' do
        expect(project.description).to eq('Nisi et repellendus ut enim quo accusamus vel magnam.')
        expect(project.labels.count).to eq(3)
        expect(project.boards.count).to eq(1)
        expect(project.project_feature).not_to be_nil
        expect(project.custom_attributes.count).to eq(2)
        expect(project.project_badges.count).to eq(2)
        expect(project.snippets.count).to eq(1)
      end
    end
  end

  shared_examples 'logging of relations creation' do
    context 'when log_import_export_relation_creation feature flag is enabled' do
      before do
        stub_feature_flags(log_import_export_relation_creation: group)
      end

      it 'logs top-level relation creation' do
        expect(relation_tree_restorer.shared.logger)
          .to receive(:info)
          .with(hash_including(message: '[Project/Group Import] Created new object relation'))
          .at_least(:once)

        subject
      end
    end

    context 'when log_import_export_relation_creation feature flag is disabled' do
      before do
        stub_feature_flags(log_import_export_relation_creation: false)
      end

      it 'does not log top-level relation creation' do
        expect(relation_tree_restorer.shared.logger)
          .to receive(:info)
          .with(hash_including(message: '[Project/Group Import] Created new object relation'))
          .never

        subject
      end
    end
  end

  context 'when restoring a project' do
    let(:importable) { create(:project, :builds_enabled, :issues_disabled, name: 'project', path: 'project') }
    let(:importable_name) { 'project' }
    let(:importable_path) { 'project' }
    let(:object_builder) { Gitlab::ImportExport::Project::ObjectBuilder }
    let(:relation_factory) { Gitlab::ImportExport::Project::RelationFactory }
    let(:reader) { Gitlab::ImportExport::Reader.new(shared: shared) }

    context 'using legacy reader' do
      let(:path) { 'spec/fixtures/lib/gitlab/import_export/complex/project.json' }
      let(:relation_reader) do
        Gitlab::ImportExport::Json::LegacyReader::File.new(
          path,
          relation_names: reader.project_relation_names,
          allowed_path: 'project'
        )
      end

      let(:attributes) { relation_reader.consume_attributes('project') }

      it_behaves_like 'import project successfully'

      context 'logging of relations creation' do
        let(:group) { create(:group) }
        let(:importable) { create(:project, :builds_enabled, :issues_disabled, name: 'project', path: 'project', group: group) }

        include_examples 'logging of relations creation'
      end
    end

    context 'using ndjson reader' do
      let(:path) { 'spec/fixtures/lib/gitlab/import_export/complex/tree' }
      let(:relation_reader) { Gitlab::ImportExport::Json::NdjsonReader.new(path) }

      it_behaves_like 'import project successfully'
    end

    context 'with invalid relations' do
      let(:path) { 'spec/fixtures/lib/gitlab/import_export/project_with_invalid_relations/tree' }
      let(:relation_reader) { Gitlab::ImportExport::Json::NdjsonReader.new(path) }

      it 'logs the invalid relation and its errors' do
        expect(relation_tree_restorer.shared.logger)
          .to receive(:warn)
          .with(
            error_messages: "Title can't be blank. Title is invalid",
            message: '[Project/Group Import] Invalid object relation built',
            relation_class: 'ProjectLabel',
            relation_index: 0,
            relation_key: 'labels'
          ).once

        relation_tree_restorer.restore
      end
    end
  end

  context 'when restoring a group' do
    let(:path) { 'spec/fixtures/lib/gitlab/import_export/group_exports/no_children/group.json' }
    let(:group) { create(:group) }
    let(:importable) { create(:group, parent: group) }
    let(:importable_name) { nil }
    let(:importable_path) { nil }
    let(:object_builder) { Gitlab::ImportExport::Group::ObjectBuilder }
    let(:relation_factory) { Gitlab::ImportExport::Group::RelationFactory }
    let(:relation_reader) do
      Gitlab::ImportExport::Json::LegacyReader::File.new(
        path,
        relation_names: reader.group_relation_names)
    end

    let(:reader) do
      Gitlab::ImportExport::Reader.new(
        shared: shared,
        config: Gitlab::ImportExport::Config.new(config: Gitlab::ImportExport.legacy_group_config_file).to_h
      )
    end

    it 'restores group tree' do
      expect(subject).to eq(true)
    end

    include_examples 'logging of relations creation'
  end
end
