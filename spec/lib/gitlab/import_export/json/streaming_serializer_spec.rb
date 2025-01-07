# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Json::StreamingSerializer, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:release) { create(:release) }
  let_it_be(:group) { create(:group) }

  let_it_be(:exportable) do
    create(:project,
      :public,
      :repository,
      :issues_disabled,
      :wiki_enabled,
      :builds_private,
      description: 'description',
      releases: [release],
      group: group,
      approvals_before_merge: 1)
  end

  let_it_be(:issue) do
    # TODO: .reload can be removed after the migration https://gitlab.com/gitlab-org/gitlab/-/issues/497857
    create(:issue,
      assignees: [user],
      project: exportable).reload
  end

  let(:exportable_path) { 'project' }
  let(:logger) { Gitlab::Export::Logger.build }
  let(:json_writer) { instance_double('Gitlab::ImportExport::Json::NdjsonWriter') }
  let(:hash) { { name: exportable.name, description: exportable.description }.stringify_keys }
  let(:include) { [] }
  let(:custom_orderer) { nil }
  let(:include_if_exportable) { {} }
  let(:user_contributions_cache_key) { "bulk_imports/#{exportable.class}/#{exportable.id}/user_contribution_ids" }

  let(:relations_schema) do
    {
      only: [:name, :description],
      include: include,
      preload: { issues: nil },
      export_reorder: custom_orderer,
      include_if_exportable: include_if_exportable
    }
  end

  subject do
    described_class.new(exportable, relations_schema, json_writer, exportable_path: exportable_path, logger: logger, current_user: user)
  end

  describe '#execute' do
    before do
      allow(json_writer).to receive(:write_attributes).with(exportable_path, hash)
    end

    it 'calls json_writer.write_attributes with proper params' do
      subject.execute
    end

    context 'with many relations' do
      let(:include) do
        [{ issues: { include: [] } }]
      end

      let(:closing_user) { create(:user) }

      before do
        create_list(:issue, 3, project: exportable, relative_position: 10000) # ascending ids, same position positive
        create_list(:issue, 3, project: exportable, relative_position: -5000) # ascending ids, same position negative
        create_list(:issue, 3, project: exportable, relative_position: 0) # ascending ids, duplicate positions
        create_list(:issue, 3, project: exportable, relative_position: nil, closed_by: closing_user) # no position, closed by a user
        create_list(:issue, 3, :with_desc_relative_position, project: exportable) # ascending ids, descending position
      end

      it 'calls json_writer.write_relation_array with proper params and clears SafeRequestStore' do
        expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, array_including(issue.to_json))
        expect(Gitlab::SafeRequestStore).to receive(:clear!)

        subject.execute
      end

      context 'when batch export raises an error' do
        it 'does not raise an error and logs' do
          allow(json_writer).to receive(:write_relation_array).and_raise(StandardError, 'Error!')
          allow(logger).to receive(:error)

          expect { subject.execute }.not_to raise_error

          expect(logger).to have_received(:error).with(
            importer: 'Import/Export',
            message: 'Error exporting relation batch',
            exception_message: 'Error!',
            exception_class: 'StandardError',
            relation: :issues,
            project_id: exportable.id,
            project_name: exportable.name,
            project_path: exportable.full_path,
            sql: nil
          )
        end

        context 'when error has sql query' do
          it 'logs the error message and the sql query' do
            allow(json_writer)
              .to receive(:write_relation_array)
              .and_raise(ActiveRecord::QueryCanceled.new('PG::QueryCanceled: statement timeout', sql: 'SQL query'))

            allow(logger).to receive(:error)

            expect { subject.execute }.not_to raise_error

            expect(logger).to have_received(:error).with(
              importer: 'Import/Export',
              message: 'Error exporting relation batch',
              exception_message: 'PG::QueryCanceled: statement timeout',
              exception_class: 'ActiveRecord::QueryCanceled',
              relation: :issues,
              project_id: exportable.id,
              project_name: exportable.name,
              project_path: exportable.full_path,
              sql: 'SQL query'
            )
          end
        end
      end

      it 'logs the relation name and the number of records to export' do
        allow(json_writer).to receive(:write_relation_array)
        allow(logger).to receive(:info)

        subject.execute

        expect(logger).to have_received(:info).with(
          importer: 'Import/Export',
          message: "Exporting issues relation. Number of records to export: 16",
          project_id: exportable.id,
          project_name: exportable.name,
          project_path: exportable.full_path
        )
      end

      context 'default relation ordering' do
        it 'orders exported issues by primary key(:id)' do
          expected_issues = exportable.issues.reorder(:id).map(&:to_json)

          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, expected_issues)

          subject.execute
        end
      end

      context 'custom relation ordering ascending' do
        let(:custom_orderer) do
          {
            issues: {
              column: :relative_position,
              direction: :asc,
              nulls_position: :nulls_last
            }
          }
        end

        it 'orders exported issues by custom column(relative_position)' do
          expected_issues = exportable.issues.reorder(:relative_position, :id).map(&:to_json)

          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, expected_issues)

          subject.execute
        end
      end

      context 'custom relation ordering descending' do
        let(:custom_orderer) do
          {
            issues: {
              column: :relative_position,
              direction: :desc,
              nulls_position: :nulls_first
            }
          }
        end

        it 'orders exported issues by custom column(relative_position)' do
          expected_issues = exportable.issues.reorder(Issue.arel_table[:relative_position].desc.nulls_first).order(id: :desc).map(&:to_json)

          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, expected_issues)

          subject.execute
        end
      end

      context 'contributing user id caching' do
        let(:json_writer) do
          Class.new do
            def write_relation_array(_, _, enumerator)
              enumerator.each(&:itself)
            end
          end.new
        end

        context 'when :importer_user_mapping feature flag is enabled' do
          it 'caches existing referenced user_ids' do
            expected_user_ref_ids = Issue.all.pluck(
              :author_id, :updated_by_id, :last_edited_by_id, :closed_by_id
            ).flatten.uniq.filter_map { |user_id| user_id.to_s if user_id }

            subject.execute

            expect(
              Gitlab::Cache::Import::Caching.values_from_set(user_contributions_cache_key)
            ).to match_array(expected_user_ref_ids)
          end
        end

        context 'when :importer_user_mapping feature flag is disabled' do
          it 'does not cache any contributing user ids' do
            stub_feature_flags(importer_user_mapping: false)

            expect(BulkImports::UserContributionsExportMapper).not_to receive(:new)
            subject.execute

            expect(Gitlab::Cache::Import::Caching.values_from_set(user_contributions_cache_key)).to be_empty
          end
        end
      end
    end

    context 'with single relation' do
      let(:group_options) do
        { include: [], only: [:name, :path, :description] }
      end

      let(:include) do
        [{ group: group_options }]
      end

      it 'calls json_writer.write_relation with proper params' do
        expect(json_writer).to receive(:write_relation).with(exportable_path, :group, group.to_json(group_options))

        subject.execute
      end

      it 'logs the relation name' do
        allow(json_writer).to receive(:write_relation)
        allow(logger).to receive(:info)

        subject.execute

        expect(logger).to have_received(:info).with(
          importer: 'Import/Export',
          message: 'Exporting group relation',
          project_id: exportable.id,
          project_name: exportable.name,
          project_path: exportable.full_path
        )
      end

      context 'contributing user id caching' do
        before do
          allow(json_writer).to receive(:write_relation)
        end

        context 'when :importer_user_mapping feature flag is enabled' do
          it 'caches existing referenced user_ids' do
            expect_next_instance_of(BulkImports::UserContributionsExportMapper) do |contribution_mapper|
              expect(contribution_mapper).to receive(:cache_user_contributions_on_record).with(group).once
            end

            subject.execute
          end
        end

        context 'when :importer_user_mapping feature flag is disabled' do
          it 'does not cache any contributing user ids' do
            stub_feature_flags(importer_user_mapping: false)

            expect(BulkImports::UserContributionsExportMapper).not_to receive(:new)
            subject.execute
          end
        end
      end
    end

    context 'with array relation' do
      let(:project_member) { create(:project_member, user: user) }
      let(:include) do
        [{ project_members: { include: [] } }]
      end

      before do
        allow(exportable).to receive(:project_members).and_return([project_member])
      end

      it 'calls json_writer.write_relation_array with proper params' do
        expect(json_writer).to receive(:write_relation_array).with(exportable_path, :project_members, array_including(project_member.to_json))

        subject.execute
      end

      it 'logs the relation name and the number of records to export' do
        allow(json_writer).to receive(:write_relation_array)
        allow(logger).to receive(:info)

        subject.execute

        expect(logger).to have_received(:info).with(
          importer: 'Import/Export',
          message: 'Exporting project_members relation. Number of records to export: 1',
          project_id: exportable.id,
          project_name: exportable.name,
          project_path: exportable.full_path
        )
      end

      context 'contributing user id caching' do
        let(:json_writer) do
          Class.new do
            def write_relation_array(_, _, enumerator)
              enumerator.each(&:itself)
            end
          end.new
        end

        before do
          project_member.update!(created_by: create(:user))
        end

        context 'when :importer_user_mapping feature flag is enabled' do
          it 'caches existing referenced user_ids' do
            expected_user_ref_ids = [project_member.user_id, project_member.created_by_id].map(&:to_s)

            subject.execute

            expect(
              Gitlab::Cache::Import::Caching.values_from_set(user_contributions_cache_key)
            ).to match_array(expected_user_ref_ids)
          end
        end

        context 'when :importer_user_mapping feature flag is disabled' do
          it 'does not cache any contributing user ids' do
            stub_feature_flags(importer_user_mapping: false)

            expect(BulkImports::UserContributionsExportMapper).not_to receive(:new)
            subject.execute

            expect(Gitlab::Cache::Import::Caching.values_from_set(user_contributions_cache_key)).to be_empty
          end
        end
      end
    end

    describe 'load balancing' do
      it 'reads from replica' do
        expect(Gitlab::Database::LoadBalancing::SessionMap)
          .to receive(:with_sessions).with(Gitlab::Database::LoadBalancing.base_models).and_call_original

        expect_next_instance_of(Gitlab::Database::LoadBalancing::ScopedSessions) do |inst|
          expect(inst).to receive(:use_replicas_for_read_queries).and_call_original
        end

        subject.execute
      end
    end

    describe 'with inaccessible associations' do
      let_it_be(:milestone) { create(:milestone, project: exportable) }
      # TODO: .reload can be removed after the migration https://gitlab.com/gitlab-org/gitlab/-/issues/497857
      let_it_be(:issue) { create(:issue, assignees: [user], project: exportable, milestone: milestone).reload }
      let_it_be(:label1) { create(:label, project: exportable) }
      let_it_be(:label2) { create(:label, project: exportable) }
      let_it_be(:link1) { create(:label_link, label: label1, target: issue) }
      let_it_be(:link2) { create(:label_link, label: label2, target: issue) }

      let(:options) { { include: [{ label_links: { include: [:label] } }, { milestone: { include: [] } }] } }

      let(:include) do
        [{ issues: options }]
      end

      shared_examples 'record with exportable associations' do
        it 'includes exportable association' do
          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, array_including(expected_issue))

          subject.execute
        end
      end

      context 'conditional export of included associations' do
        let(:include_if_exportable) do
          { issues: [:label_links, :milestone] }
        end

        context 'when association is exportable' do
          before do
            allow_next_found_instance_of(Issue) do |issue|
              allow(issue).to receive(:exportable_association?).with(:label_links, current_user: user).and_return(true)
              allow(issue).to receive(:exportable_association?).with(:milestone, current_user: user).and_return(true)
            end
          end

          it_behaves_like 'record with exportable associations' do
            let(:expected_issue) { issue.to_json(options) }
          end
        end

        context 'when an association is not exportable' do
          before do
            allow_next_found_instance_of(Issue) do |issue|
              allow(issue).to receive(:exportable_association?).with(:label_links, current_user: user).and_return(true)
              allow(issue).to receive(:exportable_association?).with(:milestone, current_user: user).and_return(false)
            end
          end

          it_behaves_like 'record with exportable associations' do
            let(:expected_issue) { issue.to_json(include: [{ label_links: { include: [:label] } }]) }
          end
        end

        context 'when association does not respond to exportable_association?' do
          before do
            allow_next_found_instance_of(Issue) do |issue|
              allow(issue).to receive(:respond_to?).and_call_original
              allow(issue).to receive(:respond_to?).with(:exportable_association?).and_return(false)
            end
          end

          it_behaves_like 'record with exportable associations' do
            let(:expected_issue) { issue.to_json }
          end
        end
      end

      context 'export of included restricted associations' do
        let(:many_relation) { :label_links }
        let(:single_relation) { :milestone }
        let(:issue_hash) { issue.as_json(options).with_indifferent_access }
        let(:expected_issue) { issue.to_json(options) }

        context 'when the association is restricted' do
          context 'when some association records are exportable' do
            before do
              allow_next_found_instance_of(Issue) do |issue|
                allow(issue).to receive(:restricted_associations).with([many_relation, single_relation]).and_return([many_relation])
                allow(issue).to receive(:readable_records).with(many_relation, current_user: user).and_return([link1])
              end
            end

            it_behaves_like 'record with exportable associations' do
              let(:expected_issue) do
                issue_hash[many_relation].delete_if { |record| record['id'] == link2.id }
                issue_hash.to_json(options)
              end
            end
          end

          context 'when all association records are exportable' do
            before do
              allow_next_found_instance_of(Issue) do |issue|
                allow(issue).to receive(:restricted_associations).with([many_relation, single_relation]).and_return([many_relation])
                allow(issue).to receive(:readable_records).with(many_relation, current_user: user).and_return([link1, link2])
              end
            end

            it_behaves_like 'record with exportable associations'
          end

          context 'when the single association record is exportable' do
            before do
              allow_next_found_instance_of(Issue) do |issue|
                allow(issue).to receive(:restricted_associations).with([many_relation, single_relation]).and_return([single_relation])
                allow(issue).to receive(:readable_records).with(single_relation, current_user: user).and_return(milestone)
              end
            end

            it_behaves_like 'record with exportable associations'
          end

          context 'when the single association record is not exportable' do
            before do
              allow_next_found_instance_of(Issue) do |issue|
                allow(issue).to receive(:restricted_associations).with([many_relation, single_relation]).and_return([single_relation])
                allow(issue).to receive(:readable_records).with(single_relation, current_user: user).and_return(nil)
              end
            end

            it_behaves_like 'record with exportable associations' do
              let(:expected_issue) do
                issue_hash[single_relation] = nil
                issue_hash.to_json(options)
              end
            end
          end
        end

        context 'when the associations are not restricted' do
          before do
            allow_next_found_instance_of(Issue) do |issue|
              allow(issue).to receive(:restricted_associations).with([many_relation, single_relation]).and_return([])
            end
          end

          it_behaves_like 'record with exportable associations'
        end
      end
    end
  end

  describe '#serialize_relation' do
    context 'when record is a merge request' do
      let(:json_writer) do
        Class.new do
          def write_relation_array(_, _, enumerator)
            enumerator.each(&:itself)
          end
        end.new
      end

      it 'removes cached external diff' do
        merge_request = create(:merge_request, source_project: exportable, target_project: exportable)
        cache_dir = merge_request.merge_request_diff.send(:external_diff_cache_dir)

        expect(subject).to receive(:remove_cached_external_diff).with(merge_request).twice

        subject.serialize_relation({ merge_requests: { include: [] } })

        expect(Dir.exist?(cache_dir)).to eq(false)
      end
    end

    context 'when the record is a user' do
      let(:json_writer) do
        Class.new do
          def write_relation_array(_, _, enumerator)
            enumerator.each(&:itself)
          end
        end.new
      end

      before do
        exportable.user_contributions = User.all
      end

      after do
        exportable.user_contributions = nil
      end

      it 'does not attempt to cache user references from a User record' do
        expect(Gitlab::Cache::Import::Caching.values_from_set(user_contributions_cache_key)).to be_empty

        subject.serialize_relation({ user_contributions: { only: [:id, :public_email, :username, :name], include: [] } })
      end
    end

    context 'when export_reduce_relation_batch_size` feature flag is enabled' do
      before do
        stub_feature_flags(export_reduce_relation_batch_size: true)
      end

      context 'when exported relation is included in SMALL_BATCH_RELATIONS' do
        before do
          stub_const("#{described_class}::SMALL_BATCH_RELATIONS", [:merge_requests])
        end

        it 'export relations using a smaller batch size' do
          expect(exportable.merge_requests).to receive(:in_batches).with(of: described_class::SMALLER_BATCH_SIZE)

          subject.serialize_relation({ merge_requests: { include: [] } })
        end
      end

      context 'when exported relation is not included in SMALL_BATCH_RELATIONS' do
        before do
          stub_const("#{described_class}::SMALL_BATCH_RELATIONS", [])
        end

        it 'export relations using the regular batch size' do
          expect(exportable.merge_requests).to receive(:in_batches).with(of: described_class::BATCH_SIZE)

          subject.serialize_relation({ merge_requests: { include: [] } })
        end
      end
    end

    context 'when export_reduce_relation_batch_size` feature flag is disabled' do
      before do
        stub_feature_flags(export_reduce_relation_batch_size: false)
      end

      it 'export relations using the regular batch size' do
        expect(exportable.merge_requests).to receive(:in_batches).with(of: described_class::BATCH_SIZE)

        subject.serialize_relation({ merge_requests: { include: [] } })
      end
    end
  end
end
