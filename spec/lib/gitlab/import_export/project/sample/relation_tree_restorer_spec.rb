# frozen_string_literal: true

# This spec is a lightweight version of:
#   * project/tree_restorer_spec.rb
#
# In depth testing is being done in the above specs.
# This spec tests that restore of the sample project works
# but does not have 100% relation coverage.

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::Sample::RelationTreeRestorer do
  include_context 'relation tree restorer shared context'

  let(:sample_data_relation_tree_restorer) do
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

  subject { sample_data_relation_tree_restorer.restore }

  shared_examples 'import project successfully' do
    it 'restores project tree' do
      expect(subject).to eq(true)
    end

    describe 'imported project' do
      let(:project) { Project.find_by_path('project') }

      before do
        subject
      end

      it 'has the project attributes and relations', :aggregate_failures do
        expect(project.description).to eq('Nisi et repellendus ut enim quo accusamus vel magnam.')
        expect(project.issues.count).to eq(10)
        expect(project.milestones.count).to eq(3)
        expect(project.labels.count).to eq(2)
        expect(project.project_feature).not_to be_nil
      end

      it 'has issues with correctly updated due dates' do
        due_dates = due_dates(project.issues)

        expect(due_dates).to match_array([Date.today - 7.days, Date.today, Date.today + 7.days])
      end

      it 'has milestones with correctly updated due dates' do
        due_dates = due_dates(project.milestones)

        expect(due_dates).to match_array([Date.today - 7.days, Date.today, Date.today + 7.days])
      end

      def due_dates(relations)
        due_dates = relations.map { |relation| relation['due_date'] }
        due_dates.compact!
        due_dates.sort
      end
    end
  end

  context 'when restoring a project' do
    let(:importable) { create(:project, :builds_enabled, :issues_disabled, name: 'project', path: 'project') }
    let(:importable_name) { 'project' }
    let(:importable_path) { 'project' }
    let(:object_builder) { Gitlab::ImportExport::Project::ObjectBuilder }
    let(:relation_factory) { Gitlab::ImportExport::Project::Sample::RelationFactory }
    let(:reader) { Gitlab::ImportExport::Reader.new(shared: shared) }
    let(:path) { 'spec/fixtures/lib/gitlab/import_export/sample_data/tree' }
    let(:relation_reader) { Gitlab::ImportExport::Json::NdjsonReader.new(path) }

    it 'initializes relation_factory with date_calculator as parameter' do
      expect(Gitlab::ImportExport::Project::Sample::RelationFactory).to receive(:create).with(hash_including(:date_calculator)).at_least(:once).times

      subject
    end

    context 'when relation tree restorer is initialized' do
      it 'initializes date calculator with due dates' do
        expect(Gitlab::ImportExport::Project::Sample::DateCalculator).to receive(:new).with(Array)

        sample_data_relation_tree_restorer
      end
    end

    context 'using ndjson reader' do
      it_behaves_like 'import project successfully'
    end
  end
end
