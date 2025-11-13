# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::CrossReferenced, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  subject(:importer) { described_class.new(project, client) }

  let_it_be_with_reload(:project) do
    create(
      :project, :in_group, :github_import,
      :import_user_mapping_enabled
    )
  end

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issue_iid) { 999 }
  let(:issuable) { create(:issue, project: project, iid: issue_iid) }
  let(:referenced_in) { build_stubbed(:issue, project: project, iid: issue_iid + 1) }
  let(:commit_id) { nil }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
      'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
      'actor' => { 'id' => 1000, 'login' => 'github_author' },
      'event' => 'cross-referenced',
      'source' => {
        'type' => 'issue',
        'issue' => {
          'number' => referenced_in.iid,
          'pull_request' => pull_request_resource
        }
      },
      'created_at' => '2022-04-26 18:30:53 UTC',
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:pull_request_resource) { nil }
  let(:cached_references) { placeholder_user_references(Import::SOURCE_GITHUB, project.import_state.id) }

  shared_examples 'import cross-referenced event' do
    context 'when referenced in other issue' do
      let(:expected_note_body) { "mentioned in issue ##{referenced_in.iid}" }

      before do
        allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
          allow(finder).to receive(:database_id).and_return(referenced_in.iid)
          allow(finder).to receive(:database_id).and_return(issuable.id)
        end
      end

      it 'creates expected note' do
        importer.execute(issue_event)

        expect(issuable.notes.count).to eq 1
        expect(issuable.notes[0]).to have_attributes expected_note_attrs
        expect(issuable.notes[0].system_note_metadata.action).to eq 'cross_reference'
      end

      it_behaves_like 'internal event tracking' do
        let(:event) { 'g_project_management_issue_cross_referenced' }
        let(:subject) { importer.execute(issue_event) }
        let(:user) { mapped_user }

        before do
          # Trigger g_project_management_issue_created event before executing subject
          # as this has a different author & increments total issue-action metrics
          issuable
        end
      end
    end

    context 'when referenced in pull request' do
      let(:referenced_in) { build_stubbed(:merge_request, project: project) }
      let(:pull_request_resource) { { 'id' => referenced_in.iid } }

      let(:expected_note_body) { "mentioned in merge request !#{referenced_in.iid}" }

      before do
        allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
          allow(finder).to receive(:database_id).and_return(referenced_in.iid)
          allow(finder).to receive(:database_id).and_return(issuable.id)
        end
      end

      it 'creates expected note' do
        importer.execute(issue_event)

        expect(issuable.notes.count).to eq 1
        expect(issuable.notes[0]).to have_attributes expected_note_attrs
        expect(issuable.notes[0].system_note_metadata.action).to eq 'cross_reference'
      end

      it_behaves_like 'internal event not tracked' do
        let(:event) { 'g_project_management_issue_cross_referenced' }

        subject { importer.execute(issue_event) }
      end
    end

    context 'when referenced in out of project issue/pull_request' do
      before do
        allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
          allow(finder).to receive(:database_id).and_return(nil)
        end
      end

      it 'does not create expected note' do
        importer.execute(issue_event)

        expect(issuable.notes.count).to eq 0
      end
    end
  end

  shared_examples 'push a placeholder reference' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        allow(finder).to receive(:database_id).and_return(referenced_in.iid)
        allow(finder).to receive(:database_id).and_return(issuable.id)
      end
    end

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
    let_it_be(:mapped_user) { source_user.mapped_user }
    let(:expected_note_attrs) do
      {
        system: true,
        noteable_type: issuable.class.name,
        noteable_id: issuable.id,
        project_id: project.id,
        author_id: mapped_user.id,
        note: expected_note_body,
        created_at: issue_event.created_at,
        imported_from: 'github'
      }.stringify_keys
    end

    context 'with Issue' do
      it_behaves_like 'import cross-referenced event'
      it_behaves_like 'push a placeholder reference'
    end

    context 'with MergeRequest' do
      let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

      it_behaves_like 'import cross-referenced event'
      it_behaves_like 'push a placeholder reference'
    end

    context 'when importing into a personal namespace' do
      let_it_be(:user_namespace) { create(:namespace) }
      let_it_be(:mapped_user) { user_namespace.owner }

      before_all do
        project.update!(namespace: user_namespace)
      end

      context 'with Issue' do
        it_behaves_like 'import cross-referenced event'
        it_behaves_like 'do not push placeholder reference'
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

        it_behaves_like 'import cross-referenced event'
        it_behaves_like 'do not push placeholder reference'
      end
    end
  end

  context 'when user mapping is disabled' do
    let_it_be(:mapped_user) { create(:user) }
    let(:expected_note_attrs) do
      {
        system: true,
        noteable_type: issuable.class.name,
        noteable_id: issuable.id,
        project_id: project.id,
        author_id: mapped_user.id,
        note: expected_note_body,
        created_at: issue_event.created_at,
        imported_from: 'github'
      }.stringify_keys
    end

    before do
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(1000, 'github_author').and_return(mapped_user.id)
      end
    end

    context 'with Issue' do
      it_behaves_like 'import cross-referenced event'
      it_behaves_like 'do not push placeholder reference'
    end

    context 'with MergeRequest' do
      let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

      it_behaves_like 'import cross-referenced event'
      it_behaves_like 'do not push placeholder reference'
    end
  end
end
