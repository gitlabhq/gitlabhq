# frozen_string_literal: true

# This spec is a lightweight version of:
#   * project/tree_restorer_spec.rb
#
# In depth testing is being done in the above specs.
# This spec tests that restore project works
# but does not have 100% relation coverage.

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::RelationTreeRestorer, feature_category: :importers do
  let_it_be(:importable, reload: true) do
    create(:project, :builds_enabled, :issues_disabled, name: 'project', path: 'project')
  end

  include_context 'relation tree restorer shared context' do
    let(:importable_name) { 'project' }
  end

  let(:reader) { Gitlab::ImportExport::Reader.new(shared: shared) }
  let(:relation_tree_restorer) do
    described_class.new(
      user: user,
      shared: shared,
      relation_reader: relation_reader,
      object_builder: Gitlab::ImportExport::Project::ObjectBuilder,
      members_mapper: members_mapper,
      relation_factory: Gitlab::ImportExport::Project::RelationFactory,
      reader: reader,
      importable: importable,
      importable_path: 'project',
      importable_attributes: attributes
    )
  end

  subject { relation_tree_restorer.restore }

  shared_examples 'import project successfully' do
    describe 'imported project' do
      it 'has the project attributes and relations', :aggregate_failures do
        expect(subject).to eq(true)

        project = Project.find_by_path('project')

        expect(project.description).to eq('Nisi et repellendus ut enim quo accusamus vel magnam.')
        expect(project.labels.count).to eq(3)
        expect(project.boards.count).to eq(1)
        expect(project.project_feature).not_to be_nil
        expect(project.custom_attributes.count).to eq(2)
        expect(project.project_badges.count).to eq(2)
        expect(project.snippets.count).to eq(1)
        expect(project.commit_notes.count).to eq(3)
      end
    end
  end

  context 'when inside a group' do
    let(:path) { 'spec/fixtures/lib/gitlab/import_export/complex/tree' }
    let(:relation_reader) { Gitlab::ImportExport::Json::NdjsonReader.new(path) }

    let_it_be(:group) do
      create(:group, :disabled_and_unoverridable).tap { |g| g.add_maintainer(user) }
    end

    before do
      importable.update!(shared_runners_enabled: false, group: group)
    end

    it_behaves_like 'import project successfully'
  end

  context 'with invalid relations' do
    let(:path) { 'spec/fixtures/lib/gitlab/import_export/project_with_invalid_relations/tree' }
    let(:relation_reader) { Gitlab::ImportExport::Json::NdjsonReader.new(path) }

    it 'logs the invalid relation and its errors' do
      expect(shared.logger)
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
