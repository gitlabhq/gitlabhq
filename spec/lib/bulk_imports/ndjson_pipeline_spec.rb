# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::NdjsonPipeline, feature_category: :importers do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:bulk_import) { create(:bulk_import, :with_configuration, user: user) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import, group: group) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker, batch_number: 1) }

  let_it_be(:source_user_1) do
    create(:import_source_user,
      import_type: ::Import::SOURCE_DIRECT_TRANSFER,
      namespace: group,
      source_user_identifier: 101,
      source_hostname: bulk_import.configuration.url
    )
  end

  let_it_be(:source_user_2) do
    create(:import_source_user,
      import_type: ::Import::SOURCE_DIRECT_TRANSFER,
      namespace: group,
      source_user_identifier: 102,
      source_hostname: bulk_import.configuration.url
    )
  end

  let_it_be(:source_user_reassigned) do
    create(:import_source_user, :completed,
      import_type: ::Import::SOURCE_DIRECT_TRANSFER,
      namespace: group,
      source_user_identifier: 103,
      source_hostname: bulk_import.configuration.url
    )
  end

  let(:klass) do
    Class.new do
      include BulkImports::NdjsonPipeline

      relation_name 'test'

      attr_reader :portable, :current_user, :context

      def initialize(portable, user, context)
        @portable = portable
        @current_user = user
        @context = context
      end
    end
  end

  before do
    stub_const('NdjsonPipelineClass', klass)
  end

  subject { NdjsonPipelineClass.new(group, user, context) }

  it 'marks pipeline as ndjson' do
    expect(NdjsonPipelineClass.file_extraction_pipeline?).to eq(true)
  end

  describe 'caching' do
    it 'saves completed entry in cache' do
      subject.save_processed_entry("entry", 10)

      expected_cache_key = "ndjson_pipeline_class/#{entity.id}/1"
      expect(Gitlab::Cache::Import::Caching.read(expected_cache_key)).to eq("10")
    end

    context "when is not a batched pipeline" do
      let(:context) { BulkImports::Pipeline::Context.new(tracker) }

      it 'saves completed entry using batch number 0' do
        subject.save_processed_entry("entry", 10)

        expected_cache_key = "ndjson_pipeline_class/#{entity.id}/0"
        expect(Gitlab::Cache::Import::Caching.read(expected_cache_key)).to eq("10")
      end
    end

    it 'identifies completed entries' do
      subject.save_processed_entry("entry", 10)

      expect(subject.already_processed?("entry", 11)).to be_falsy
      expect(subject.already_processed?("entry", 10)).to be_truthy
      expect(subject.already_processed?("entry", 9)).to be_truthy
    end
  end

  describe '#deep_transform_relation!' do
    it 'transforms relation hash' do
      transformed = subject.deep_transform_relation!({}, 'test', {}) do |key, hash|
        hash.merge(relation_key: key)
      end

      expect(transformed[:relation_key]).to eq('test')
    end

    context 'when importer_user_mapping is enabled' do
      before do
        allow(context).to receive(:importer_user_mapping_enabled?).and_return(true)

        stub_const("#{described_class}::IGNORE_PLACEHOLDER_USER_CREATION", {})
      end

      let(:relation_hash) do
        {
          "author_id" => source_user_1.source_user_identifier,
          "updated_by_id" => nil,
          "last_edited_by_id" => 107,
          "project_id" => 1,
          "title" => "Imported MR",
          "approvals" => [{ "user_id" => 108 }],
          "notes" =>
          [
            {
              "note" => "Issue note",
              "author_id" => source_user_reassigned.source_user_identifier,
              "award_emoji" => [
                {
                  "name" => "clapper", "user_id" => 105
                },
                {
                  "name" => "clapper", "user_id" => source_user_2.source_user_identifier
                }
              ]
            },
            {
              "note" => "Issue note 2",
              "author_id" => 106
            }
          ],
          "merge_request_assignees" => [
            {
              "user_id" => source_user_reassigned.source_user_identifier
            },
            {
              "user_id" => 104
            }
          ],
          "metrics" => {
            "merged_by_id" => 105
          }
        }
      end

      let(:relation_definition) do
        {
          "approvals" => {},
          "metrics" => {},
          "award_emoji" => {},
          "merge_request_assignees" => {},
          "notes" => { "author" => {}, "award_emoji" => {} }
        }
      end

      it 'creates for each user reference in relation hash an Import::SourceUser object if they do not exist' do
        expect { subject.deep_transform_relation!(relation_hash, 'test', relation_definition) { |a, _b| a } }
          .to change { Import::SourceUser.count }.by(5).and change { User.count }.by(5)
        expect(Import::SourceUser.pluck(:source_user_identifier)).to match_array(%w[101 102 103 104 105 106 107 108])
      end

      context 'when relation hash includes attributes that placeholder user creation should be ignored' do
        before do
          stub_const("#{described_class}::IGNORE_PLACEHOLDER_USER_CREATION", {
            'test' => ['last_edited_by_id'],
            'approvals' => ['user_id']
          })
        end

        it 'does not create a source user for the ignored user references' do
          subject.deep_transform_relation!(relation_hash, 'test', relation_definition) { |a, _b| a }

          expect(Import::SourceUser.pluck(:source_user_identifier)).to match_array(%w[101 102 103 104 105 106])
        end
      end
    end

    context 'when subrelations is an array' do
      it 'transforms each element of the array' do
        relation_hash = {
          'key' => 'value',
          'labels' => [
            { 'title' => 'label 1' },
            { 'title' => 'label 2' },
            { 'title' => 'label 3' }
          ]
        }
        relation_definition = { 'labels' => {} }

        transformed = subject.deep_transform_relation!(relation_hash, 'test', relation_definition) do |key, hash|
          hash.merge(relation_key: key)
        end

        transformed['labels'].each do |label|
          expect(label[:relation_key]).to eq('labels')
        end
      end
    end

    context 'when subrelation is a hash' do
      it 'transforms subrelation hash' do
        relation_hash = {
          'key' => 'value',
          'label' => { 'title' => 'label' }
        }
        relation_definition = { 'label' => {} }

        transformed = subject.deep_transform_relation!(relation_hash, 'test', relation_definition) do |key, hash|
          hash.merge(relation_key: key)
        end

        expect(transformed['label'][:relation_key]).to eq('label')
      end
    end

    context 'when subrelation is nil' do
      it 'removes subrelation' do
        relation_hash = {
          'key' => 'value',
          'label' => { 'title' => 'label' }
        }
        relation_definition = { 'label' => {} }

        transformed = subject.deep_transform_relation!(relation_hash, 'test', relation_definition) do |key, hash|
          if key == 'label'
            nil
          else
            hash
          end
        end

        expect(transformed['label']).to be_nil
      end
    end
  end

  describe '#transform' do
    let(:hash) { { key: :value } }
    let(:data) { [hash, 1] }
    let(:config) { double(relation_excluded_keys: nil, top_relation_tree: []) }

    before do
      allow(subject).to receive(:import_export_config).and_return(config)
      allow(subject).to receive(:context).and_return(context)
    end

    it 'calls relation factory' do
      relation_object = double

      expect(Gitlab::ImportExport::Group::RelationFactory)
        .to receive(:create)
        .with(
          relation_index: 1,
          relation_sym: :test,
          relation_hash: hash,
          importable: group,
          members_mapper: instance_of(BulkImports::UsersMapper),
          object_builder: Gitlab::ImportExport::Group::ObjectBuilder,
          user: user,
          excluded_keys: nil,
          import_source: Import::SOURCE_DIRECT_TRANSFER,
          original_users_map: {},
          rewrite_mentions: false
        )
        .and_return(relation_object)
      expect(relation_object).to receive(:assign_attributes).with(group: group)

      subject.transform(context, data)
    end

    context 'when importer_user_mapping is enabled' do
      before do
        allow(context).to receive(:importer_user_mapping_enabled?).and_return(true)
      end

      it 'calls relation factory with SourceUsersMapper' do
        expect(Gitlab::ImportExport::Group::RelationFactory)
        .to receive(:create)
        .with(
          relation_index: 1,
          relation_sym: :test,
          relation_hash: hash,
          importable: group,
          members_mapper: instance_of(Import::BulkImports::SourceUsersMapper),
          object_builder: Gitlab::ImportExport::Group::ObjectBuilder,
          user: user,
          excluded_keys: nil,
          import_source: Import::SOURCE_DIRECT_TRANSFER,
          original_users_map: {},
          rewrite_mentions: true
        ).and_return(double(assign_attributes: nil))

        subject.transform(context, data)
      end
    end

    context 'when data is nil' do
      before do
        expect(Gitlab::ImportExport::Group::RelationFactory).not_to receive(:create)
      end

      it 'returns' do
        expect(subject.transform(nil, nil)).to be_nil
      end

      context 'when relation hash is nil' do
        it 'returns' do
          expect(subject.transform(nil, [nil, 0])).to be_nil
        end
      end
    end
  end

  describe '#load' do
    context 'when object is not persisted' do
      it 'saves the object using RelationObjectSaver' do
        object = double(persisted?: false, new_record?: true)

        allow(subject).to receive(:relation_definition)

        expect_next_instance_of(Gitlab::ImportExport::Base::RelationObjectSaver) do |saver|
          expect(saver).to receive(:execute)
        end

        subject.load(nil, [object])
      end

      context 'when object is invalid' do
        it 'captures invalid subrelations' do
          object = group.labels.new(priorities: [LabelPriority.new])
          object.validate

          allow_next_instance_of(Gitlab::ImportExport::Base::RelationObjectSaver) do |saver|
            allow(saver).to receive(:execute)
            allow(saver).to receive(:invalid_subrelations).and_return(object.priorities)
          end

          subject.load(context, [object])

          failure = entity.failures.first

          expect(failure.pipeline_class).to eq(tracker.pipeline_name)
          expect(failure.subrelation).to eq('LabelPriority')
          expect(failure.exception_class).to eq('RecordInvalid')
          expect(failure.exception_message).to eq("Project can't be blank, Priority can't be blank, and Priority is not a number")
        end
      end
    end

    context 'when object is persisted' do
      it 'saves the object' do
        object = double(new_record?: false, invalid?: false)

        expect(object).to receive(:save!)

        subject.load(nil, [object])
      end

      context 'when object is invalid' do
        it 'raises ActiveRecord::RecordInvalid exception' do
          object = build_stubbed(:issue)

          expect(Gitlab::Import::Errors).to receive(:merge_nested_errors).with(object)

          expect { subject.load(nil, [object]) }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when object is missing' do
      it 'returns nil' do
        expect(subject.load(nil, [nil])).to be_nil
      end
    end

    context 'when importer_user_mapping is enabled' do
      before do
        allow(context).to receive(:importer_user_mapping_enabled?).and_return(true)
        allow(subject).to receive(:relation_definition).and_return(
          { "notes" => { "events" => {}, "system_note_metadata" => {} } }
        )
      end

      it 'pushes a placeholder reference for the persisted objects' do
        merge_request = build(:merge_request,
          source_project: project,
          target_project: project,
          author: source_user_1.mapped_user,
          updated_by: source_user_1.mapped_user
        )
        note = build(:note,
          project: project,
          author: source_user_1.mapped_user,
          updated_by: source_user_2.mapped_user
        )
        merge_request.notes << note
        event = build(:event,
          author: source_user_1.mapped_user
        )
        note.events << event

        original_users_map = {}.compare_by_identity
        original_users_map[merge_request] = {
          'author_id' => source_user_1.source_user_identifier,
          'updated_by_id' => source_user_1.source_user_identifier
        }
        original_users_map[note] = {
          'author_id' => source_user_1.source_user_identifier,
          'updated_by_id' => source_user_2.source_user_identifier
        }
        original_users_map[event] = {
          'author_id' => source_user_1.source_user_identifier
        }

        expect(Import::PlaceholderReferences::PushService).to receive(:from_record).with(
          import_source: ::Import::SOURCE_DIRECT_TRANSFER,
          import_uid: context.bulk_import_id,
          record: merge_request,
          user_reference_column: :author_id,
          source_user: source_user_1
        ).and_call_original

        expect(::Import::PlaceholderReferences::PushService).to receive(:from_record).with(
          import_source: ::Import::SOURCE_DIRECT_TRANSFER,
          import_uid: context.bulk_import_id,
          record: merge_request,
          user_reference_column: :updated_by_id,
          source_user: source_user_1
        ).and_call_original

        expect(::Import::PlaceholderReferences::PushService).to receive(:from_record).with(
          import_source: ::Import::SOURCE_DIRECT_TRANSFER,
          import_uid: context.bulk_import_id,
          record: note,
          user_reference_column: :author_id,
          source_user: source_user_1
        ).and_call_original

        expect(::Import::PlaceholderReferences::PushService).to receive(:from_record).with(
          import_source: ::Import::SOURCE_DIRECT_TRANSFER,
          import_uid: context.bulk_import_id,
          record: note,
          user_reference_column: :updated_by_id,
          source_user: source_user_2
        ).and_call_original

        expect(::Import::PlaceholderReferences::PushService).to receive(:from_record).with(
          import_source: ::Import::SOURCE_DIRECT_TRANSFER,
          import_uid: context.bulk_import_id,
          record: event,
          user_reference_column: :author_id,
          source_user: source_user_1
        ).and_call_original

        subject.load(nil, [merge_request, original_users_map])
      end

      context 'when source user is mapped to a real user' do
        it 'does not push a placeholder reference' do
          merge_request = build(:merge_request,
            source_project: project,
            target_project: project,
            author: source_user_reassigned.mapped_user,
            updated_by: source_user_reassigned.mapped_user
          )

          original_users_map = {}.compare_by_identity
          original_users_map[merge_request] = {
            'author_id' => source_user_reassigned.source_user_identifier,
            'updated_by_id' => source_user_reassigned.source_user_identifier
          }

          expect(::Import::PlaceholderReferences::PushService).not_to receive(:from_record)

          subject.load(nil, [merge_request, original_users_map])
        end
      end

      context 'when an exception is raised when saving a nested object' do
        it 'still pushes a placeholder reference for the persisted objects' do
          merge_request = build(:merge_request,
            source_project: project,
            target_project: project,
            author: source_user_1.mapped_user
          )

          note = build(:note,
            project: project,
            author: source_user_1.mapped_user
          )

          diff_note = build(:diff_note_on_merge_request,
            project: project,
            author: source_user_1.mapped_user
          )
          allow(diff_note).to receive(:save).and_raise(DiffNote::NoteDiffFileCreationError)

          merge_request.notes << note
          merge_request.notes << diff_note

          original_users_map = {}.compare_by_identity
          original_users_map[merge_request] = {
            'author_id' => source_user_1.source_user_identifier
          }
          original_users_map[note] = {
            'author_id' => source_user_1.source_user_identifier
          }
          original_users_map[diff_note] = {
            'author_id' => source_user_1.source_user_identifier
          }

          expect(Import::PlaceholderReferences::PushService).to receive(:from_record).with(
            import_source: ::Import::SOURCE_DIRECT_TRANSFER,
            import_uid: context.bulk_import_id,
            record: merge_request,
            user_reference_column: :author_id,
            source_user: source_user_1
          ).and_call_original

          expect(Import::PlaceholderReferences::PushService).to receive(:from_record).with(
            import_source: ::Import::SOURCE_DIRECT_TRANSFER,
            import_uid: context.bulk_import_id,
            record: note,
            user_reference_column: :author_id,
            source_user: source_user_1
          ).and_call_original

          expect { subject.load(nil, [merge_request, original_users_map]) }.to raise_error(
            DiffNote::NoteDiffFileCreationError
          )
        end
      end
    end
  end

  describe '#relation_class' do
    context 'when relation name is pluralized' do
      it 'returns constantized class' do
        expect(subject.relation_class('MergeRequest::Metrics')).to eq(MergeRequest::Metrics)
      end
    end

    context 'when relation name is singularized' do
      it 'returns constantized class' do
        expect(subject.relation_class('Badge')).to eq(Badge)
      end
    end
  end

  describe '#relation_key_override' do
    context 'when portable is group' do
      it 'returns group relation name override' do
        expect(subject.relation_key_override('labels')).to eq('group_labels')
      end
    end

    context 'when portable is project' do
      subject { NdjsonPipelineClass.new(project, user, context) }

      it 'returns group relation name override' do
        expect(subject.relation_key_override('labels')).to eq('project_labels')
      end
    end
  end

  describe '#relation_factory' do
    context 'when portable is group' do
      it 'returns group relation factory' do
        expect(subject.relation_factory).to eq(Gitlab::ImportExport::Group::RelationFactory)
      end
    end

    context 'when portable is project' do
      subject { NdjsonPipelineClass.new(project, user, context) }

      it 'returns project relation factory' do
        expect(subject.relation_factory).to eq(Gitlab::ImportExport::Project::RelationFactory)
      end
    end
  end
end
