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

      it 'assigns the correct import source' do
        expect(subject).to eq(true)

        project = Project.find_by_path('project')

        issues = project.issues
        snippets = project.snippets
        merge_requests = project.merge_requests
        notes = project.notes

        expect(issues.map).to all(have_attributes(imported_from: 'gitlab_project'))
        expect(snippets.map).to all(have_attributes(imported_from: 'gitlab_project'))
        expect(merge_requests.map).to all(have_attributes(imported_from: 'gitlab_project'))
        expect(notes.map).to all(have_attributes(imported_from: 'gitlab_project'))
      end
    end
  end

  context 'when inside a group' do
    let(:path) { 'spec/fixtures/lib/gitlab/import_export/complex/tree' }
    let(:relation_reader) { Gitlab::ImportExport::Json::NdjsonReader.new(path) }

    let_it_be(:group) do
      create(:group, :shared_runners_disabled_and_unoverridable, maintainers: user)
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

  describe '#restore_single_relation' do
    let_it_be(:importable) { create(:project) }

    let(:relation_reader) do
      Gitlab::ImportExport::Json::NdjsonReader.new(
        'spec/fixtures/lib/gitlab/import_export/complex/tree'
      )
    end

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
        importable_path: importable_name,
        importable_attributes: attributes,
        skip_on_duplicate_iid: skip_on_duplicate_iid
      )
    end

    subject(:restore_relations) { relation_tree_restorer.restore_single_relation(relation_key) }

    shared_examples 'saving single relation' do
      context 'when skipping existing IIDs' do
        let(:skip_on_duplicate_iid) { true }

        it 'does not attempt to save the duplicate relation' do
          expect(relation_tree_restorer).not_to receive(:save_relation_object)

          restore_relations
        end
      end

      context 'when not skipping existing IIDs' do
        let(:skip_on_duplicate_iid) { false }

        it 'attempts to save the duplicate relation' do
          expect(relation_tree_restorer).to receive(:save_relation_object).once

          restore_relations
        end
      end
    end

    context 'when importing issues' do
      let(:relation_key) { 'issues' }

      before do
        importable.issues.create!(iid: 123, title: 'Issue', author: user)

        allow(relation_reader)
          .to receive(:consume_relation)
          .with(importable_name, 'issues')
          .and_return([[build(:issue, iid: 123, title: 'Issue', author_id: user.id), 0]])
      end

      include_examples 'saving single relation'
    end

    context 'when importing milestones' do
      let(:relation_key) { 'milestones' }

      before do
        importable.milestones.create!(iid: 123, title: 'Milestone')

        allow(relation_reader)
          .to receive(:consume_relation)
          .with(importable_name, 'milestones')
          .and_return([[build(:milestone, iid: 123, name: 'Milestone'), 0]])
      end

      include_examples 'saving single relation'
    end

    context 'when importing CI pipelines' do
      let(:relation_key) { 'ci_pipelines' }

      before do
        create(
          :ci_pipeline,
          project: importable,
          iid: 123
        )

        allow(relation_reader)
          .to receive(:consume_relation)
          .with(importable_name, 'ci_pipelines')
          .and_return([[build(:ci_pipeline, iid: 123), 0]])
      end

      include_examples 'saving single relation'
    end

    context 'when importing merge requests' do
      let(:relation_key) { 'merge_requests' }

      before do
        create(
          :merge_request,
          iid: 123,
          source_project: importable,
          target_project: importable
        )

        allow(relation_reader)
          .to receive(:consume_relation)
          .with(importable_name, 'merge_requests')
          .and_return([[build(:merge_request, iid: 123), 0]])
      end

      include_examples 'saving single relation'
    end

    context 'when importing an unknown relation' do
      let(:relation_key) { 'unknown' }
      let(:skip_on_duplicate_iid) { false }

      it 'does not attempt an import' do
        expect(relation_tree_restorer).not_to receive(:save_relation_object)

        restore_relations
      end
    end
  end
end
