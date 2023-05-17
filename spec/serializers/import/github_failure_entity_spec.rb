# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubFailureEntity, feature_category: :importers do
  let(:project) { instance_double(Project, id: 123456, import_url: 'https://github.com/example/repo.git', import_source: 'example/repo') }
  let(:source) { 'Gitlab::GithubImport::Importer::PullRequestImporter' }
  let(:github_identifiers) { { 'iid' => 2, 'object_type' => 'pull_request', 'title' => 'Implement cool feature' } }
  let(:import_failure) do
    instance_double(
      ImportFailure,
      project: project,
      exception_class: 'Some class',
      exception_message: 'Something went wrong',
      source: source,
      correlation_id_value: '2ea9c4b8587b6df49f35a3fb703688aa',
      external_identifiers: github_identifiers,
      created_at: Time.current
    )
  end

  let(:failure_details) do
    {
      exception_class: import_failure.exception_class,
      exception_message: import_failure.exception_message,
      correlation_id_value: import_failure.correlation_id_value,
      source: import_failure.source,
      github_identifiers: github_identifiers,
      created_at: import_failure.created_at
    }
  end

  subject(:entity) { described_class.new(import_failure).as_json.with_indifferent_access }

  shared_examples 'import failure entity' do
    it 'exposes required fields for import entity' do
      expect(entity).to eq(
        {
          type: import_failure.external_identifiers['object_type'],
          title: title,
          provider_url: provider_url,
          details: failure_details
        }.with_indifferent_access
      )
    end
  end

  it 'exposes correct attributes' do
    expect(entity.keys).to match_array(%w[type title provider_url details])
  end

  context 'with `pull_request` failure' do
    it_behaves_like 'import failure entity' do
      let(:title) { 'Implement cool feature' }
      let(:provider_url) { 'https://github.com/example/repo/pull/2' }
    end
  end

  context 'with `pull_request_merged_by` failure' do
    before do
      import_failure.external_identifiers.merge!({ 'object_type' => 'pull_request_merged_by' })
    end

    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::PullRequests::MergedByImporter' }
      let(:title) { 'Pull request 2 merger' }
      let(:provider_url) { 'https://github.com/example/repo/pull/2' }
    end
  end

  context 'with `pull_request_review_request` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::PullRequests::ReviewRequestImporter' }
      let(:title) { 'Pull request 2 review request' }
      let(:provider_url) { 'https://github.com/example/repo/pull/2' }
      let(:github_identifiers) do
        {
          'merge_request_iid' => 2,
          'requested_reviewers' => %w[alice bob],
          'object_type' => 'pull_request_review_request'
        }
      end
    end
  end

  context 'with `pull_request_review` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::PullRequests::ReviewImporter' }
      let(:title) { 'Pull request review 123456' }
      let(:provider_url) { 'https://github.com/example/repo/pull/2#pullrequestreview-123456' }
      let(:github_identifiers) do
        {
          'merge_request_iid' => 2,
          'review_id' => 123456,
          'object_type' => 'pull_request_review'
        }
      end
    end
  end

  context 'with `issue` failure' do
    before do
      import_failure.external_identifiers.merge!({ 'object_type' => 'issue' })
    end

    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::IssueAndLabelLinksImporter' }
      let(:title) { 'Implement cool feature' }
      let(:provider_url) { 'https://github.com/example/repo/issues/2' }
    end
  end

  context 'with `collaborator` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::CollaboratorImporter' }
      let(:title) { 'alice' }
      let(:provider_url) { 'https://github.com/alice' }
      let(:github_identifiers) do
        {
          'id' => 123456,
          'login' => 'alice',
          'object_type' => 'collaborator'
        }
      end
    end
  end

  context 'with `protected_branch` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::ProtectedBranchImporter' }
      let(:title) { 'main' }
      let(:provider_url) { 'https://github.com/example/repo/tree/main' }
      let(:github_identifiers) do
        {
          'id' => 'main',
          'object_type' => 'protected_branch'
        }
      end
    end
  end

  context 'with `issue_event` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::IssueEventImporter' }
      let(:title) { 'closed' }
      let(:provider_url) { 'https://github.com/example/repo/issues/2#event-123456' }
      let(:github_identifiers) do
        {
          'id' => 123456,
          'issuable_iid' => 2,
          'event' => 'closed',
          'object_type' => 'issue_event'
        }
      end
    end
  end

  context 'with `label` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::LabelsImporter' }
      let(:title) { 'bug' }
      let(:provider_url) { 'https://github.com/example/repo/labels/bug' }
      let(:github_identifiers) { { 'title' => 'bug', 'object_type' => 'label' } }
    end
  end

  context 'with `milestone` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::MilestonesImporter' }
      let(:title) { '1 release' }
      let(:provider_url) { 'https://github.com/example/repo/milestone/1' }
      let(:github_identifiers) { { 'iid' => 1, 'title' => '1 release',  'object_type' => 'milestone' } }
    end
  end

  context 'with `release` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::ReleasesImporter' }
      let(:title) { 'v1.0' }
      let(:provider_url) { 'https://github.com/example/repo/releases/tag/v1.0' }
      let(:github_identifiers) do
        {
          'tag' => 'v1.0',
          'object_type' => 'release'
        }
      end
    end
  end

  context 'with `note` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::NoteImporter' }
      let(:title) { 'MergeRequest comment 123456' }
      let(:provider_url) { 'https://github.com/example/repo/issues/2#issuecomment-123456' }
      let(:github_identifiers) do
        {
          'note_id' => 123456,
          'noteable_iid' => 2,
          'noteable_type' => 'MergeRequest',
          'object_type' => 'note'
        }
      end
    end
  end

  context 'with `diff_note` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::DiffNoteImporter' }
      let(:title) { 'Pull request review comment 123456' }
      let(:provider_url) { 'https://github.com/example/repo/pull/2#discussion_r123456' }
      let(:github_identifiers) do
        {
          'note_id' => 123456,
          'noteable_iid' => 2,
          'noteable_type' => 'MergeRequest',
          'object_type' => 'diff_note'
        }
      end
    end
  end

  context 'with `issue_attachment` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::NoteAttachmentsImporter' }
      let(:title) { 'Issue 2 attachment' }
      let(:provider_url) { 'https://github.com/example/repo/issues/2' }
      let(:github_identifiers) do
        {
          'db_id' => 123456,
          'noteable_iid' => 2,
          'object_type' => 'issue_attachment'
        }
      end
    end
  end

  context 'with `merge_request_attachment` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::NoteAttachmentsImporter' }
      let(:title) { 'Merge request 2 attachment' }
      let(:provider_url) { 'https://github.com/example/repo/pull/2' }
      let(:github_identifiers) do
        {
          'db_id' => 123456,
          'noteable_iid' => 2,
          'object_type' => 'merge_request_attachment'
        }
      end
    end
  end

  context 'with `release_attachment` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::NoteAttachmentsImporter' }
      let(:title) { 'Release v1.0 attachment' }
      let(:provider_url) { 'https://github.com/example/repo/releases/tag/v1.0' }
      let(:github_identifiers) do
        {
          'db_id' => 123456,
          'tag' => 'v1.0',
          'object_type' => 'release_attachment'
        }
      end
    end
  end

  context 'with `note_attachment` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::NoteAttachmentsImporter' }
      let(:title) { 'Note attachment' }
      let(:provider_url) { '' }
      let(:github_identifiers) do
        {
          'db_id' => 123456,
          'noteable_type' => 'Issue',
          'object_type' => 'note_attachment'
        }
      end
    end
  end

  context 'with `lfs_object` failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::LfsObjectImporter' }
      let(:title) { '42' }
      let(:provider_url) { '' }
      let(:github_identifiers) do
        {
          'oid' => 42,
          'size' => 123456,
          'object_type' => 'lfs_object'
        }
      end
    end
  end

  context 'with unknown failure' do
    it_behaves_like 'import failure entity' do
      let(:source) { 'Gitlab::GithubImport::Importer::NewObjectTypeImporter' }
      let(:title) { '' }
      let(:provider_url) { '' }
      let(:github_identifiers) do
        {
          'id' => 123456,
          'object_type' => 'new_object_type'
        }
      end
    end
  end

  context 'with an invalid import_url' do
    let(:project) { instance_double(Project, id: 123456, import_url: 'Invalid url', import_source: 'example/repo') }

    it_behaves_like 'import failure entity' do
      let(:title) { 'Implement cool feature' }
      let(:provider_url) { '' }
    end
  end
end
