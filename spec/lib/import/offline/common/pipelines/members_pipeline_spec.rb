# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Common::Pipelines::MembersPipeline, feature_category: :importers do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, owners: current_user) }
  let_it_be_with_reload(:bulk_import) do
    create(:bulk_import, :with_offline_configuration, user: current_user)
  end

  let(:entity) do
    create(
      :bulk_import_entity,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_namespace: group.full_path,
      group: group
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
    allow(context).to receive(:importer_user_mapping_enabled?).and_return(true)
    allow(pipeline).to receive(:set_source_objects_counter)
    allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
      allow(extractor).to receive(:extract).and_return(
        BulkImports::Pipeline::ExtractedData.new(data: [[member_data, 0]])
      )
      allow(extractor).to receive(:remove_tmpdir)
    end
  end

  it 'uses the members NDJSON file' do
    expect(described_class.get_extractor).to eq(
      klass: BulkImports::Common::Extractors::NdjsonExtractor,
      options: { relation: 'members' }
    )
  end

  it 'is a file extraction pipeline' do
    expect(described_class.file_extraction_pipeline?).to be(true)
  end

  it 'uses the base members pipeline transformers' do
    expect(described_class.transformers).to eq(described_class.superclass.transformers)
  end

  context 'when the member is nil' do
    it 'skips the member' do
      expect(pipeline.transform(context, [nil, 0])).to be_nil
    end
  end

  context 'when the member has no source user ID' do
    before do
      member_data['user'].delete('id')
    end

    it 'skips the member' do
      expect { pipeline.run }
        .to not_change { Import::SourceUser.count }
        .and not_change { Import::Placeholders::Membership.count }
    end
  end

  context 'when the source user is mapped to a user' do
    let_it_be(:source_user) do
      create(
        :import_source_user,
        :completed,
        namespace: group,
        source_user_identifier: '101',
        source_hostname: bulk_import.offline_configuration.source_hostname,
        import_type: Import::SOURCE_OFFLINE_TRANSFER
      )
    end

    it 'creates a membership for the mapped user' do
      expect { pipeline.run }
        .to change { group.members.count }.by(1)
        .and not_change { Import::SourceUser.count }
        .and not_change { Import::Placeholders::Membership.count }

      expect(group.members.find_by!(user: source_user.reassign_to_user)).to have_attributes(access_level: 30)
    end
  end

  describe '#after_run' do
    it 'calls extractor#remove_tmpdir' do
      extractor = pipeline.send(:file_extractor)
      expect(extractor).to receive(:remove_tmpdir)

      pipeline.after_run(nil)
    end
  end

  it 'imports the member as a placeholder membership' do
    expect { pipeline.run }
      .to change { Import::SourceUser.count }.by(1)
      .and change { Import::Placeholders::Membership.count }.by(1)

    source_user = Import::SourceUser.find_by!(source_user_identifier: '101')

    expect(source_user).to have_attributes(
      source_name: 'Source member',
      source_username: 'source_member',
      import_type: Import::SOURCE_OFFLINE_TRANSFER.to_s
    )

    expect(Import::Placeholders::Membership.find_by!(source_user: source_user)).to have_attributes(
      access_level: 30,
      group_id: group.id,
      project_id: nil
    )
  end
end
