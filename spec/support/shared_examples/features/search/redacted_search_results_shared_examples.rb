# frozen_string_literal: true

RSpec.shared_examples 'a redacted search results' do
  let_it_be(:user) { create(:user) }

  let_it_be(:accessible_group) { create(:group, :private) }
  let_it_be(:accessible_project) { create(:project, :repository, :private, name: 'accessible_project') }

  let_it_be(:group_member) { create(:group_member, group: accessible_group, user: user) }

  let_it_be(:inaccessible_group) { create(:group, :private) }
  let_it_be(:inaccessible_project) { create(:project, :repository, :private, name: 'inaccessible_project') }

  let(:search) { 'anything' }

  subject(:result) { search_service.search_objects }

  def found_blob(project)
    Gitlab::Search::FoundBlob.new(project: project)
  end

  def found_wiki_page(project)
    Gitlab::Search::FoundWikiPage.new(found_blob(project))
  end

  def ar_relation(klass, *objects)
    klass.id_in(objects.map(&:id))
  end

  def kaminari_array(*objects)
    Kaminari.paginate_array(objects).page(1).per(20)
  end

  before do
    accessible_project.add_maintainer(user)

    allow(search_service)
      .to receive_message_chain(:search_results, :objects)
            .and_return(unredacted_results)
  end

  context 'for issues' do
    let(:readable) { create(:issue, project: accessible_project) }
    let(:unreadable) { create(:issue, project: inaccessible_project) }
    let(:unredacted_results) { ar_relation(Issue, readable, unreadable) }
    let(:scope) { 'issues' }

    it 'redacts the inaccessible issue' do
      expect(search_service.send(:logger))
        .to receive(:error)
        .with(
          hash_including(
            message: "redacted_search_results",
            current_user_id: user.id,
            query: search,
            filtered: array_including(
              [
                { class_name: 'Issue', id: unreadable.id, ability: :read_issue }
              ]
            )
          )
        )

      expect(result).to contain_exactly(readable)
    end
  end

  context 'for notes' do
    let(:readable_merge_request) do
      create(:merge_request_with_diffs, target_project: accessible_project, source_project: accessible_project)
    end

    let(:readable_note_on_commit) { create(:note_on_commit, project: accessible_project) }
    let(:readable_diff_note) { create(:diff_note_on_commit, project: accessible_project) }
    let(:readable_note_on_mr) do
      create(:discussion_note_on_merge_request, noteable: readable_merge_request, project: accessible_project)
    end

    let(:readable_diff_note_on_mr) do
      create(:diff_note_on_merge_request, noteable: readable_merge_request, project: accessible_project)
    end

    let(:readable_note_on_project_snippet) do
      create(:note_on_project_snippet, noteable: readable_merge_request, project: accessible_project)
    end

    let(:unreadable_merge_request) do
      create(:merge_request_with_diffs, target_project: inaccessible_project, source_project: inaccessible_project)
    end

    let(:unreadable_note_on_commit) { create(:note_on_commit, project: inaccessible_project) }
    let(:unreadable_diff_note) { create(:diff_note_on_commit, project: inaccessible_project) }
    let(:unreadable_note_on_mr) do
      create(:discussion_note_on_merge_request, noteable: unreadable_merge_request, project: inaccessible_project)
    end

    let(:unreadable_note_on_project_snippet) do
      create(:note_on_project_snippet, noteable: unreadable_merge_request, project: inaccessible_project)
    end

    let(:unredacted_results) do
      ar_relation(
        Note,
        readable_note_on_commit,
        readable_diff_note,
        readable_note_on_mr,
        readable_diff_note_on_mr,
        readable_note_on_project_snippet,
        unreadable_note_on_commit,
        unreadable_diff_note,
        unreadable_note_on_mr,
        unreadable_note_on_project_snippet
      )
    end

    let(:scope) { 'notes' }

    it 'redacts the inaccessible notes' do
      expect(search_service.send(:logger))
        .to receive(:error)
        .with(
          hash_including(
            message: "redacted_search_results",
            current_user_id: user.id,
            query: search,
            filtered: array_including(
              [
                { class_name: 'Note', id: unreadable_note_on_commit.id, ability: :read_note },
                { class_name: 'DiffNote', id: unreadable_diff_note.id, ability: :read_note },
                { class_name: 'DiscussionNote', id: unreadable_note_on_mr.id, ability: :read_note },
                { class_name: 'Note', id: unreadable_note_on_project_snippet.id, ability: :read_note }
              ]
            )
          )
        )

      expect(result).to contain_exactly(
        readable_note_on_commit,
        readable_diff_note,
        readable_note_on_mr,
        readable_diff_note_on_mr,
        readable_note_on_project_snippet
      )
    end
  end

  context 'for merge_requests' do
    let(:readable) { create(:merge_request, source_project: accessible_project) }
    let(:unreadable) { create(:merge_request, source_project: inaccessible_project) }
    let(:unredacted_results) { ar_relation(MergeRequest, readable, unreadable) }
    let(:scope) { 'merge_requests' }

    it 'redacts the inaccessible merge request' do
      expect(search_service.send(:logger))
        .to receive(:error)
        .with(
          hash_including(
            message: "redacted_search_results",
            current_user_id: user.id,
            query: search,
            filtered: array_including(
              [
                { class_name: 'MergeRequest', id: unreadable.id, ability: :read_merge_request }
              ]
            )
          )
        )

      expect(result).to contain_exactly(readable)
    end

    context 'with :with_api_entity_associations' do
      let(:unredacted_results) { ar_relation(MergeRequest.with_api_entity_associations, readable, unreadable) }

      it_behaves_like "redaction limits N+1 queries", limit: 10
    end
  end

  context 'for blobs' do
    let(:readable) { found_blob(accessible_project) }
    let(:unreadable) { found_blob(inaccessible_project) }
    let(:unredacted_results) { kaminari_array(readable, unreadable) }
    let(:scope) { 'blobs' }

    it 'redacts the inaccessible blob' do
      expect(search_service.send(:logger))
        .to receive(:error)
        .with(
          hash_including(
            message: "redacted_search_results",
            current_user_id: user.id,
            query: search,
            filtered: array_including(
              [
                { class_name: 'Gitlab::Search::FoundBlob', id: unreadable.id, ability: :read_blob }
              ]
            )
          )
        )

      expect(result).to contain_exactly(readable)
    end
  end

  context 'for wiki blobs' do
    let(:readable) { found_wiki_page(accessible_project) }
    let(:unreadable) { found_wiki_page(inaccessible_project) }
    let(:unredacted_results) { kaminari_array(readable, unreadable) }
    let(:scope) { 'wiki_blobs' }

    it 'redacts the inaccessible blob' do
      expect(search_service.send(:logger))
        .to receive(:error)
        .with(
          hash_including(
            message: "redacted_search_results",
            current_user_id: user.id,
            query: search,
            filtered: array_including(
              [
                { class_name: 'Gitlab::Search::FoundWikiPage', id: unreadable.id, ability: :read_wiki_page }
              ]
            )
          )
        )

      expect(result).to contain_exactly(readable)
    end
  end

  context 'for project snippets' do
    let(:readable) { create(:project_snippet, project: accessible_project) }
    let(:unreadable) { create(:project_snippet, project: inaccessible_project) }
    let(:unredacted_results) { ar_relation(ProjectSnippet, readable, unreadable) }
    let(:scope) { 'snippet_titles' }

    it 'redacts the inaccessible snippet' do
      expect(search_service.send(:logger))
        .to receive(:error)
        .with(
          hash_including(
            message: "redacted_search_results",
            current_user_id: user.id,
            query: search,
            filtered: array_including(
              [
                { class_name: 'ProjectSnippet', id: unreadable.id, ability: :read_snippet }
              ]
            )
          )
        )

      expect(result).to contain_exactly(readable)
    end

    context 'with :with_api_entity_associations' do
      it_behaves_like "redaction limits N+1 queries", limit: 15
    end
  end

  context 'for personal snippets' do
    let(:readable) { create(:personal_snippet, :private, author: user) }
    let(:unreadable) { create(:personal_snippet, :private) }
    let(:unredacted_results) { ar_relation(PersonalSnippet, readable, unreadable) }
    let(:scope) { 'snippet_titles' }

    it 'redacts the inaccessible snippet' do
      expect(search_service.send(:logger))
        .to receive(:error)
        .with(
          hash_including(
            message: "redacted_search_results",
            current_user_id: user.id,
            query: search,
            filtered: array_including(
              [
                { class_name: 'PersonalSnippet', id: unreadable.id, ability: :read_snippet }
              ]
            )
          )
        )

      expect(result).to contain_exactly(readable)
    end

    context 'with :with_api_entity_associations' do
      it_behaves_like "redaction limits N+1 queries", limit: 4
    end
  end

  context 'for commits' do
    let(:readable) { accessible_project.commit }
    let(:unreadable) { inaccessible_project.commit }
    let(:unredacted_results) { kaminari_array(readable, unreadable) }
    let(:scope) { 'commits' }

    it 'redacts the inaccessible commit' do
      expect(search_service.send(:logger))
        .to receive(:error)
        .with(
          hash_including(
            message: "redacted_search_results",
            current_user_id: user.id,
            query: search,
            filtered: array_including(
              [
                { class_name: 'Commit', id: unreadable.id, ability: :read_commit }
              ]
            )
          )
        )

      expect(result).to contain_exactly(readable)
    end
  end

  context 'for users' do
    let(:other_user) { create(:user) }
    let(:unredacted_results) { ar_relation(User, user, other_user) }
    let(:scope) { 'users' }

    it 'passes the users through' do
      # Users are always visible to everyone
      expect(result).to contain_exactly(user, other_user)
    end
  end
end

RSpec.shared_examples "redaction limits N+1 queries" do |limit:|
  it 'does not exceed the query limit' do
    # issuing the query to remove the data loading call
    unredacted_results.to_a

    # only the calls from the redaction are left
    query = ActiveRecord::QueryRecorder.new { result }

    # these are the project authorization calls, which are not preloaded
    expect(query.count).to be <= limit
  end
end
