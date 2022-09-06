# frozen_string_literal: true

# This spec is a lightweight version of:
#   * project/tree_restorer_spec.rb
#
# In depth testing is being done in the above specs.
# This spec tests that restore project works
# but does not have 100% relation coverage.

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Group::RelationTreeRestorer do
  let(:group) { create(:group).tap { |g| g.add_owner(user) } }
  let(:importable) { create(:group, parent: group) }

  include_context 'relation tree restorer shared context' do
    let(:importable_name) { nil }
  end

  let(:path) { 'spec/fixtures/lib/gitlab/import_export/group_exports/no_children/group.json' }
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

  let(:relation_tree_restorer) do
    described_class.new(
      user: user,
      shared: shared,
      relation_reader: relation_reader,
      object_builder: Gitlab::ImportExport::Group::ObjectBuilder,
      members_mapper: members_mapper,
      relation_factory: Gitlab::ImportExport::Group::RelationFactory,
      reader: reader,
      importable: importable,
      importable_path: nil,
      importable_attributes: attributes
    )
  end

  subject { relation_tree_restorer.restore }

  it 'restores group tree' do
    expect(subject).to eq(true)
  end

  it 'logs top-level relation creation' do
    expect(shared.logger)
      .to receive(:info)
      .with(hash_including(message: '[Project/Group Import] Created new object relation'))
      .at_least(:once)

    subject
  end
end
