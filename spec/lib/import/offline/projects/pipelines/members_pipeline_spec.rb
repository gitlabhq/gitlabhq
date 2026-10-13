# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Projects::Pipelines::MembersPipeline, feature_category: :importers do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, owners: current_user) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be_with_reload(:bulk_import) do
    create(:bulk_import, :with_offline_configuration, user: current_user)
  end

  let(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      bulk_import: bulk_import,
      project: project,
      source_full_path: 'source/full/path',
      destination_namespace: group.full_path
    )
  end

  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let(:member_data) do
    {
      'access_level' => 30,
      'created_at' => '2020-01-01T00:00:00Z',
      'updated_at' => '2020-01-02T00:00:00Z',
      'expires_at' => nil,
      'user' => {
        'id' => 101,
        'public_email' => 'member@example.com',
        'username' => 'source_member',
        'name' => 'Source member'
      }
    }
  end

  subject(:pipeline) { described_class.new(context) }

  before do
    allow(pipeline).to receive(:set_source_objects_counter)
    allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
      allow(extractor).to receive(:extract).and_return(
        BulkImports::Pipeline::ExtractedData.new(data: [[member_data, 0]])
      )
      allow(extractor).to receive(:remove_tmpdir)
    end
  end

  it 'uses the project members NDJSON file' do
    expect(described_class.get_extractor).to eq(
      klass: BulkImports::Common::Extractors::NdjsonExtractor,
      options: { relation: 'project_members' }
    )
  end

  it 'imports the member as a placeholder membership' do
    expect { pipeline.run }
      .to change { Import::SourceUser.count }.by(1)
      .and change { Import::Placeholders::Membership.count }.by(1)

    source_user = Import::SourceUser.find_by!(source_user_identifier: '101')

    expect(Import::Placeholders::Membership.find_by!(source_user: source_user)).to have_attributes(
      access_level: 30,
      group_id: nil,
      project_id: project.id
    )
  end
end
