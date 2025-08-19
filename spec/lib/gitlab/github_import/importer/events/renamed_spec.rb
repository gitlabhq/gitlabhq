# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Renamed, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  subject(:importer) { described_class.new(project, client) }

  let_it_be_with_reload(:project) do
    create(
      :project, :in_group, :github_import,
      :import_user_mapping_enabled, :user_mapping_to_personal_namespace_owner_enabled
    )
  end

  let_it_be(:user) { create(:user) }

  let(:issuable) { create(:issue, project: project) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => 1000, 'login' => 'github_author' },
      'event' => 'renamed',
      'commit_id' => nil,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'old_title' => 'old title',
      'new_title' => 'new title',
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:cached_references) { placeholder_user_references(Import::SOURCE_GITHUB, project.import_state.id) }

  let(:expected_system_note_metadata_attrs) do
    {
      action: "title",
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at
    }.stringify_keys
  end

  describe '#execute' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        allow(finder).to receive(:database_id).and_return(issuable.id)
      end
    end

    shared_examples 'import renamed event' do
      it 'creates expected note' do
        expect { importer.execute(issue_event) }.to change { issuable.notes.count }
          .from(0).to(1)

        expect(issuable.notes.last)
          .to have_attributes(expected_note_attrs)
      end

      it 'creates expected system note metadata' do
        expect { importer.execute(issue_event) }.to change { SystemNoteMetadata.count }
            .from(0).to(1)

        expect(SystemNoteMetadata.last)
          .to have_attributes(
            expected_system_note_metadata_attrs.merge(
              note_id: Note.last.id
            )
          )
      end
    end

    shared_examples 'push a placeholder reference' do
      it 'pushes the reference' do
        importer.execute(issue_event)

        expect(cached_references).to match_array([
          ['Note', an_instance_of(Integer), 'author_id', source_user.id]
        ])
      end
    end

    shared_examples 'do not push placeholder reference' do
      it 'does not push any reference' do
        importer.execute(issue_event)

        expect(cached_references).to be_empty
      end
    end

    context 'when user mapping is enabled' do
      let_it_be(:source_user) { generate_source_user(project, 1000) }
      let(:mapped_user_id) { source_user.mapped_user_id }
      let(:expected_note_attrs) do
        {
          noteable_id: issuable.id,
          noteable_type: issuable.class.name,
          project_id: project.id,
          author_id: mapped_user_id,
          note: "changed title from **{-old-} title** to **{+new+} title**",
          system: true,
          created_at: issue_event.created_at,
          updated_at: issue_event.created_at,
          imported_from: 'github'
        }.stringify_keys
      end

      context 'with Issue' do
        it_behaves_like 'import renamed event'
        it_behaves_like 'push a placeholder reference'
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

        it_behaves_like 'import renamed event'
        it_behaves_like 'push a placeholder reference'
      end

      context 'when importing into a personal namespace' do
        let_it_be(:user_namespace) { create(:namespace) }
        let(:mapped_user_id) { user_namespace.owner_id }

        before_all do
          project.update!(namespace: user_namespace)
        end

        context 'with Issue' do
          it_behaves_like 'import renamed event'
          it_behaves_like 'do not push placeholder reference'
        end

        context 'with MergeRequest' do
          let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

          it_behaves_like 'import renamed event'
          it_behaves_like 'do not push placeholder reference'
        end

        context 'when user_mapping_to_personal_namespace_owner is disabled' do
          let_it_be(:source_user) { generate_source_user(project, 1000) }
          let(:mapped_user_id) { source_user.mapped_user_id }

          before_all do
            project.build_or_assign_import_data(
              data: { user_mapping_to_personal_namespace_owner_enabled: false }
            ).save!
          end

          context 'with Issue' do
            it_behaves_like 'import renamed event'
            it_behaves_like 'push a placeholder reference'
          end

          context 'with MergeRequest' do
            let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

            it_behaves_like 'import renamed event'
            it_behaves_like 'push a placeholder reference'
          end
        end
      end
    end

    context 'when user mapping is disabled' do
      let(:mapped_user_id) { user.id }
      let(:expected_note_attrs) do
        {
          noteable_id: issuable.id,
          noteable_type: issuable.class.name,
          project_id: project.id,
          author_id: mapped_user_id,
          note: "changed title from **{-old-} title** to **{+new+} title**",
          system: true,
          created_at: issue_event.created_at,
          updated_at: issue_event.created_at,
          imported_from: 'github'
        }.stringify_keys
      end

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
        allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
          allow(finder).to receive(:find).with(1000, 'github_author').and_return(user.id)
        end
      end

      context 'with Issue' do
        it_behaves_like 'import renamed event'
        it_behaves_like 'do not push placeholder reference'
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

        it_behaves_like 'import renamed event'
        it_behaves_like 'do not push placeholder reference'
      end
    end
  end
end
