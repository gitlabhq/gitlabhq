# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::Common::Transformers::SourceUserMemberAttributesTransformer,
  feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:bulk_import) { create(:bulk_import, :with_configuration, user: user) }

  shared_examples 'import source user members attribute transformer' do
    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let_it_be(:import_source_user) do
      create(:import_source_user,
        namespace: context.portable.root_ancestor,
        source_hostname: bulk_import.configuration.url,
        import_type: Import::SOURCE_DIRECT_TRANSFER,
        source_user_identifier: '101'
      )
    end

    let_it_be(:reassigned_import_source_user) do
      create(:import_source_user, :completed,
        namespace: context.portable.root_ancestor,
        source_hostname: bulk_import.configuration.url,
        import_type: Import::SOURCE_DIRECT_TRANSFER,
        source_user_identifier: '102'
      )
    end

    let(:importer_user_mapping_enabled) { true }

    before do
      allow(context).to receive(:importer_user_mapping_enabled?).and_return(importer_user_mapping_enabled)
    end

    context 'when an import source user exists and is mapped to a user' do
      let(:data) { member_data(source_user_id: reassigned_import_source_user.source_user_identifier) }

      it 'does not create an import source user' do
        expect { subject.transform(context, data) }.not_to change { Import::SourceUser.count }
      end

      it 'returns member hash with the reassigned_to_user_id' do
        expect(subject.transform(context, data)).to eq(
          access_level: 30,
          user_id: reassigned_import_source_user.reassign_to_user_id,
          created_by_id: user.id,
          created_at: '2020-01-01T00:00:00Z',
          updated_at: '2020-01-01T00:00:00Z',
          expires_at: nil
        )
      end

      context 'when access level is invalid' do
        let(:data) do
          member_data(access_level: 999, source_user_id: reassigned_import_source_user.source_user_identifier)
        end

        it 'ignores record' do
          expect(subject.transform(context, data)).to eq(nil)
        end
      end

      context 'when importer_user_mapping is disabled' do
        let(:importer_user_mapping_enabled) { false }

        it 'does not create an import source user' do
          expect { subject.transform(context, data) }.not_to change { Import::SourceUser.count }
        end

        it 'does not transform the data' do
          expect(subject.transform(context, { id: 1 })).to eq({ id: 1 })
        end
      end
    end

    context 'when an import source user does not exist' do
      let(:data) { member_data(source_user_id: 999) }

      it 'creates an import source user' do
        expect { subject.transform(context, data) }.to change { Import::SourceUser.count }.by(1)

        expect(Import::SourceUser.last).to have_attributes(
          source_user_identifier: '999',
          source_username: 'source_username',
          source_name: 'source_name',
          import_type: Import::SOURCE_DIRECT_TRANSFER.to_s
        )
      end

      it 'returns placeholder membership hash' do
        expect(subject.transform(context, data)).to eq(
          source_user: Import::SourceUser.last,
          access_level: 30,
          expires_at: nil,
          group: entity.group,
          project: entity.project
        )
      end

      context 'when importer_user_mapping is disabled' do
        let(:importer_user_mapping_enabled) { false }

        it 'does not create an import source user' do
          expect { subject.transform(context, data) }.not_to change { Import::SourceUser.count }
        end

        it 'does not transform the data' do
          expect(subject.transform(context, { id: 1 })).to eq({ id: 1 })
        end
      end
    end

    context 'when an import source user exists and is mapped to placeholder user' do
      let(:data) { member_data(source_user_id: import_source_user.source_user_identifier) }

      it 'does not create an import source user' do
        expect { subject.transform(context, data) }.not_to change { Import::SourceUser.count }
      end

      it 'returns placeholder membership hash' do
        expect(subject.transform(context, data)).to eq(
          source_user: import_source_user,
          access_level: 30,
          expires_at: nil,
          group: entity.group,
          project: entity.project
        )
      end
    end

    context 'when data is nil' do
      it 'returns nil' do
        expect(subject.transform(context, nil)).to eq(nil)
      end
    end

    context 'when ActiveRecord::RecordNotUnique is raised when creating the source user' do
      before do
        allow_next_instance_of(Gitlab::Import::SourceUserMapper) do |mapper|
          allow(mapper).to receive(:find_or_create_source_user).and_raise(ActiveRecord::RecordNotUnique)
        end
      end

      it 'raises BulkImports::RetryPipelineError' do
        expect { subject.transform(context, data) }.to raise_error { BulkImports::RetryPipelineError }
      end
    end
  end

  context 'with a project' do
    let_it_be(:project) { create(:project) }
    let_it_be(:entity) { create(:bulk_import_entity, :project_entity, bulk_import: bulk_import, project: project) }

    include_examples 'import source user members attribute transformer'
  end

  context 'with a group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import, group: group) }

    include_examples 'import source user members attribute transformer'
  end

  def member_data(source_user_id:, access_level: 30)
    {
      'created_at' => '2020-01-01T00:00:00Z',
      'updated_at' => '2020-01-01T00:00:00Z',
      'expires_at' => nil,
      'access_level' => {
        'integer_value' => access_level
      },
      'user' => {
        'user_gid' => "gid://gitlab/User/#{source_user_id}",
        'username' => 'source_username',
        'name' => 'source_name'
      }
    }
  end
end
