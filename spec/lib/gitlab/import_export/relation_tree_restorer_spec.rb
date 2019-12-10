# frozen_string_literal: true

# This spec is a lightweight version of:
#   * project_tree_restorer_spec.rb
#
# In depth testing is being done in the above specs.
# This spec tests that restore project works
# but does not have 100% relation coverage.

require 'spec_helper'

describe Gitlab::ImportExport::RelationTreeRestorer do
  include ImportExport::CommonUtil

  let(:user) { create(:user) }
  let(:shared) { Gitlab::ImportExport::Shared.new(importable) }
  let(:members_mapper) { Gitlab::ImportExport::MembersMapper.new(exported_members: {}, user: user, importable: importable) }

  let(:importable_hash) do
    json = IO.read(path)
    ActiveSupport::JSON.decode(json)
  end

  let(:relation_tree_restorer) do
    described_class.new(
      user:             user,
      shared:           shared,
      tree_hash:        tree_hash,
      importable:       importable,
      members_mapper:   members_mapper,
      relation_factory: relation_factory,
      reader:           reader
    )
  end

  subject { relation_tree_restorer.restore }

  context 'when restoring a project' do
    let(:path) { 'spec/fixtures/lib/gitlab/import_export/complex/project.json' }
    let(:importable) { create(:project, :builds_enabled, :issues_disabled, name: 'project', path: 'project') }
    let(:relation_factory) { Gitlab::ImportExport::RelationFactory }
    let(:reader) { Gitlab::ImportExport::Reader.new(shared: shared) }
    let(:tree_hash) { importable_hash }

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
end
