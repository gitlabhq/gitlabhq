# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Common::Pipelines::UserContributionsPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:imported_project) { create(:project, group: group) }
  let_it_be_with_reload(:bulk_import) do
    create(:bulk_import, :with_offline_configuration, user: user)
  end

  let_it_be_with_reload(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: imported_project,
      bulk_import: bulk_import,
      destination_namespace: group.full_path
    )
  end

  let_it_be_with_reload(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:pipeline) { described_class.new(context) }

  describe 'pipeline attributes' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }

    it 'has the correct extractor' do
      expect(described_class.get_extractor).to eq(
        klass: BulkImports::Common::Extractors::NdjsonExtractor,
        options: { relation: 'user_contributions' }
      )
    end

    it 'is a file extraction pipeline' do
      expect(described_class.file_extraction_pipeline?).to be(true)
    end

    it 'has the correct relation name' do
      expect(described_class.relation).to eq('user_contributions')
    end
  end

  describe '#transform' do
    it 'returns the relation hash from extracted data' do
      data = [{ 'id' => '42', 'username' => 'alice', 'name' => 'Alice' }, 0]

      expect(pipeline.transform(context, data)).to eq(
        { 'id' => '42', 'username' => 'alice', 'name' => 'Alice' }
      )
    end

    it 'stringifies the user identifier' do
      data = [{ 'id' => 42, 'username' => 'alice', 'name' => 'Alice' }, 0]

      expect(pipeline.transform(context, data)).to eq(
        { 'id' => '42', 'username' => 'alice', 'name' => 'Alice' }
      )
    end

    it 'returns nil when data is nil' do
      expect(pipeline.transform(context, nil)).to be_nil
    end

    it 'returns nil when relation hash is nil' do
      expect(pipeline.transform(context, [nil, 0])).to be_nil
    end
  end

  describe '#load' do
    let_it_be_with_reload(:source_user) do
      create(:import_source_user,
        namespace: group,
        source_user_identifier: '42',
        source_name: nil,
        source_username: nil,
        import_type: Import::SOURCE_OFFLINE_TRANSFER,
        source_hostname: 'https://offline.example.com'
      )
    end

    context 'when source user exists and is missing attributes' do
      let(:data) { { 'id' => '42', 'username' => 'alice', 'name' => 'Alice' } }

      it 'updates the source user with name and username' do
        expect { pipeline.load(context, data) }
          .to change { source_user.reload.source_name }.from(nil).to('Alice')
          .and change { source_user.source_username }.from(nil).to('alice')
      end

      context 'when the id is an integer' do
        let(:data) { { 'id' => 42, 'username' => 'bob', 'name' => 'Bob' } }

        it 'updates the source user' do
          expect { pipeline.load(context, data) }
            .to change { source_user.reload.source_name }.from(nil).to('Bob')
            .and change { source_user.source_username }.from(nil).to('bob')
        end
      end
    end

    context 'when source user is not found' do
      let(:data) { { 'id' => '999', 'username' => 'bob', 'name' => 'Bob' } }

      it 'logs a warning and does not call UpdateService', :aggregate_failures do
        expect(pipeline).to receive(:warn).with(
          hash_including(
            message: 'Source user not found',
            source_user_identifier: '999'
          )
        )
        expect(Import::SourceUsers::UpdateService).not_to receive(:new)

        pipeline.load(context, data)
      end
    end

    context 'when data is nil' do
      it 'does not call UpdateService' do
        expect(Import::SourceUsers::UpdateService).not_to receive(:new)

        pipeline.load(context, nil)
      end
    end

    context 'when id is missing from data' do
      let(:data) { { 'username' => 'alice', 'name' => 'Alice' } }

      it 'logs a warning and does not call UpdateService', :aggregate_failures do
        expect(pipeline).to receive(:warn).with(
          hash_including(message: 'Missing source user identifier')
        )
        expect(Import::SourceUsers::UpdateService).not_to receive(:new)

        pipeline.load(context, data)
      end
    end

    context 'when data is missing name and username' do
      let(:data) { { 'id' => '42' } }

      it 'logs a warning and does not call UpdateService', :aggregate_failures do
        expect(pipeline).to receive(:warn).with(
          hash_including(
            message: 'Missing source user information',
            source_user_id: source_user.id
          )
        )
        expect(Import::SourceUsers::UpdateService).not_to receive(:new)

        pipeline.load(context, data)
      end
    end

    context 'when UpdateService returns an error' do
      let(:data) { { 'id' => '42', 'username' => 'carol', 'name' => 'Carol' } }

      before do
        allow_next_instance_of(Import::SourceUsers::UpdateService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(message: 'something went wrong')
          )
        end
      end

      it 'logs a warning and does not raise', :aggregate_failures do
        expect(pipeline).to receive(:warn).with(
          hash_including(
            message: 'Failed to update source user',
            source_user_id: source_user.id
          )
        )

        expect { pipeline.load(context, data) }.not_to raise_error
      end
    end
  end

  describe '#run', :clean_gitlab_redis_shared_state do
    let_it_be_with_reload(:source_user) do
      create(:import_source_user,
        namespace: group,
        source_user_identifier: '100',
        source_name: nil,
        source_username: nil,
        import_type: Import::SOURCE_OFFLINE_TRANSFER,
        source_hostname: 'https://offline.example.com'
      )
    end

    let(:extracted_data) do
      BulkImports::Pipeline::ExtractedData.new(data: [[{ 'id' => '100', 'username' => 'alice', 'name' => 'Alice' }, 0]])
    end

    before do
      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(extracted_data)
        allow(extractor).to receive(:remove_tmpdir)
      end

      allow(pipeline).to receive(:set_source_objects_counter)
    end

    it 'updates source user name and username' do
      expect { pipeline.run }
        .to change { source_user.reload.source_name }.from(nil).to('Alice')
        .and change { source_user.source_username }.from(nil).to('alice')
    end

    context 'when multiple entries are extracted' do
      let_it_be_with_reload(:source_user_2) do
        create(:import_source_user,
          namespace: group,
          source_user_identifier: '101',
          source_name: nil,
          source_username: nil,
          import_type: Import::SOURCE_OFFLINE_TRANSFER,
          source_hostname: 'https://offline.example.com'
        )
      end

      let(:extracted_data) do
        BulkImports::Pipeline::ExtractedData.new(data: [
          [{ 'id' => '100', 'username' => 'alice', 'name' => 'Alice' }, 0],
          [{ 'id' => '101', 'username' => 'bob', 'name' => 'Bob' }, 1]
        ])
      end

      it 'updates all source users' do
        pipeline.run

        expect(source_user.reload.source_name).to eq('Alice')
        expect(source_user_2.reload.source_name).to eq('Bob')
      end
    end

    context 'when the entity is already failed' do
      before do
        entity.fail_op!
      end

      it 'skips the pipeline' do
        expect { pipeline.run }.not_to change { source_user.reload.source_name }

        expect(tracker.reload.skipped?).to be(true)
      end
    end

    context 'when the extractor returns no data' do
      let(:extracted_data) { nil }

      it 'does not raise and does not update any source user' do
        expect { pipeline.run }.not_to change { source_user.reload.source_name }
      end
    end

    context 'when source user is not found' do
      let(:extracted_data) do
        BulkImports::Pipeline::ExtractedData.new(
          data: [[{ 'id' => '999', 'username' => 'ghost', 'name' => 'Ghost' }, 0]]
        )
      end

      it 'does not raise' do
        expect { pipeline.run }.not_to raise_error
      end
    end

    context 'when data is missing name and username' do
      let(:extracted_data) do
        BulkImports::Pipeline::ExtractedData.new(data: [[{ 'id' => '100' }, 0]])
      end

      it 'does not update the source user' do
        expect { pipeline.run }.not_to change { source_user.reload.source_name }
      end
    end

    context 'when UpdateService returns an error' do
      before do
        allow_next_instance_of(Import::SourceUsers::UpdateService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'something went wrong'))
        end
      end

      it 'does not raise' do
        expect { pipeline.run }.not_to raise_error
      end
    end
  end

  describe '#after_run' do
    it 'calls extractor#remove_tmpdir' do
      expect_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        expect(extractor).to receive(:remove_tmpdir)
      end

      pipeline.after_run(nil)
    end
  end
end
