# frozen_string_literal: true

require 'spec_helper'

describe SearchService do
  let(:user) { create(:user) }

  let(:accessible_group) { create(:group, :private) }
  let(:inaccessible_group) { create(:group, :private) }
  let!(:group_member) { create(:group_member, group: accessible_group, user: user) }

  let!(:accessible_project) { create(:project, :private, name: 'accessible_project') }
  let(:note) { create(:note_on_issue, project: accessible_project) }

  let!(:inaccessible_project) { create(:project, :private, name: 'inaccessible_project') }

  let(:snippet) { create(:snippet, author: user) }
  let(:group_project) { create(:project, group: accessible_group, name: 'group_project') }
  let(:public_project) { create(:project, :public, name: 'public_project') }

  subject(:search_service) { described_class.new(user, search: search, scope: scope, page: 1) }

  before do
    accessible_project.add_maintainer(user)
  end

  describe '#project' do
    context 'when the project is accessible' do
      it 'returns the project' do
        project = described_class.new(user, project_id: accessible_project.id).project

        expect(project).to eq accessible_project
      end

      it 'returns the project for guests' do
        search_project = create :project
        search_project.add_guest(user)

        project = described_class.new(user, project_id: search_project.id).project

        expect(project).to eq search_project
      end
    end

    context 'when the project is not accessible' do
      it 'returns nil' do
        project = described_class.new(user, project_id: inaccessible_project.id).project

        expect(project).to be_nil
      end
    end

    context 'when there is no project_id' do
      it 'returns nil' do
        project = described_class.new(user).project

        expect(project).to be_nil
      end
    end
  end

  describe '#group' do
    context 'when the group is accessible' do
      it 'returns the group' do
        group = described_class.new(user, group_id: accessible_group.id).group

        expect(group).to eq accessible_group
      end
    end

    context 'when the group is not accessible' do
      it 'returns nil' do
        group = described_class.new(user, group_id: inaccessible_group.id).group

        expect(group).to be_nil
      end
    end

    context 'when there is no group_id' do
      it 'returns nil' do
        group = described_class.new(user).group

        expect(group).to be_nil
      end
    end
  end

  describe '#show_snippets?' do
    context 'when :snippets is \'true\'' do
      it 'returns true' do
        show_snippets = described_class.new(user, snippets: 'true').show_snippets?

        expect(show_snippets).to be_truthy
      end
    end

    context 'when :snippets is not \'true\'' do
      it 'returns false' do
        show_snippets = described_class.new(user, snippets: 'tru').show_snippets?

        expect(show_snippets).to be_falsey
      end
    end

    context 'when :snippets is missing' do
      it 'returns false' do
        show_snippets = described_class.new(user).show_snippets?

        expect(show_snippets).to be_falsey
      end
    end
  end

  describe '#scope' do
    context 'with accessible project_id' do
      context 'and allowed scope' do
        it 'returns the specified scope' do
          scope = described_class.new(user, project_id: accessible_project.id, scope: 'notes').scope

          expect(scope).to eq 'notes'
        end
      end

      context 'and disallowed scope' do
        it 'returns the default scope' do
          scope = described_class.new(user, project_id: accessible_project.id, scope: 'projects').scope

          expect(scope).to eq 'blobs'
        end
      end

      context 'and no scope' do
        it 'returns the default scope' do
          scope = described_class.new(user, project_id: accessible_project.id).scope

          expect(scope).to eq 'blobs'
        end
      end
    end

    context 'with \'true\' snippets' do
      context 'and allowed scope' do
        it 'returns the specified scope' do
          scope = described_class.new(user, snippets: 'true', scope: 'snippet_titles').scope

          expect(scope).to eq 'snippet_titles'
        end
      end

      context 'and disallowed scope' do
        it 'returns the default scope' do
          scope = described_class.new(user, snippets: 'true', scope: 'projects').scope

          expect(scope).to eq 'snippet_blobs'
        end
      end

      context 'and no scope' do
        it 'returns the default scope' do
          scope = described_class.new(user, snippets: 'true').scope

          expect(scope).to eq 'snippet_blobs'
        end
      end
    end

    context 'with no project_id, no snippets' do
      context 'and allowed scope' do
        it 'returns the specified scope' do
          scope = described_class.new(user, scope: 'issues').scope

          expect(scope).to eq 'issues'
        end
      end

      context 'and disallowed scope' do
        it 'returns the default scope' do
          scope = described_class.new(user, scope: 'blobs').scope

          expect(scope).to eq 'projects'
        end
      end

      context 'and no scope' do
        it 'returns the default scope' do
          scope = described_class.new(user).scope

          expect(scope).to eq 'projects'
        end
      end
    end
  end

  describe '#search_results' do
    context 'with accessible project_id' do
      it 'returns an instance of Gitlab::ProjectSearchResults' do
        search_results = described_class.new(
          user,
          project_id: accessible_project.id,
          scope: 'notes',
          search: note.note).search_results

        expect(search_results).to be_a Gitlab::ProjectSearchResults
      end
    end

    context 'with accessible project_id and \'true\' snippets' do
      it 'returns an instance of Gitlab::ProjectSearchResults' do
        search_results = described_class.new(
          user,
          project_id: accessible_project.id,
          snippets: 'true',
          scope: 'notes',
          search: note.note).search_results

        expect(search_results).to be_a Gitlab::ProjectSearchResults
      end
    end

    context 'with \'true\' snippets' do
      it 'returns an instance of Gitlab::SnippetSearchResults' do
        search_results = described_class.new(
          user,
          snippets: 'true',
          search: snippet.content).search_results

        expect(search_results).to be_a Gitlab::SnippetSearchResults
      end
    end

    context 'with no project_id and no snippets' do
      it 'returns an instance of Gitlab::SearchResults' do
        search_results = described_class.new(
          user,
          search: public_project.name).search_results

        expect(search_results).to be_a Gitlab::SearchResults
      end
    end
  end

  describe '#search_objects' do
    context 'with accessible project_id' do
      it 'returns objects in the project' do
        search_objects = described_class.new(
          user,
          project_id: accessible_project.id,
          scope: 'notes',
          search: note.note).search_objects

        expect(search_objects.first).to eq note
      end
    end

    context 'with accessible project_id and \'true\' snippets' do
      it 'returns objects in the project' do
        search_objects = described_class.new(
          user,
          project_id: accessible_project.id,
          snippets: 'true',
          scope: 'notes',
          search: note.note).search_objects

        expect(search_objects.first).to eq note
      end
    end

    context 'with \'true\' snippets' do
      it 'returns objects in snippets' do
        search_objects = described_class.new(
          user,
          snippets: 'true',
          search: snippet.content).search_objects

        expect(search_objects.first).to eq snippet
      end
    end

    context 'with accessible group_id' do
      it 'returns objects in the group' do
        search_objects = described_class.new(
          user,
          group_id: accessible_group.id,
          search: group_project.name).search_objects

        expect(search_objects.first).to eq group_project
      end
    end

    context 'with no project_id, group_id or snippets' do
      it 'returns objects in global' do
        search_objects = described_class.new(
          user,
          search: public_project.name).search_objects

        expect(search_objects.first).to eq public_project
      end
    end

    context 'redacting search results' do
      shared_examples 'it redacts incorrect results' do
        before do
          allow(Ability).to receive(:allowed?).and_return(allowed)
        end

        context 'when allowed' do
          let(:allowed) { true }

          it 'does nothing' do
            expect(results).not_to be_empty
            expect(results).to all(be_an(model_class))
          end
        end

        context 'when disallowed' do
          let(:allowed) { false }

          it 'does nothing' do
            expect(results).to be_empty
          end
        end
      end

      context 'issues' do
        let(:issue) { create(:issue, project: accessible_project) }
        let(:scope) { 'issues' }
        let(:model_class) { Issue }
        let(:ability) { :read_issue }
        let(:search) { issue.title }
        let(:results) { subject.search_objects }

        it_behaves_like 'it redacts incorrect results'
      end

      context 'notes' do
        let(:note) { create(:note_on_commit, project: accessible_project) }
        let(:scope) { 'notes' }
        let(:model_class) { Note }
        let(:ability) { :read_note }
        let(:search) { note.note }
        let(:results) do
          described_class.new(
            user,
            project_id: accessible_project.id,
            scope: scope,
            search: note.note
          ).search_objects
        end

        it_behaves_like 'it redacts incorrect results'
      end

      context 'merge_requests' do
        let(:scope) { 'merge_requests' }
        let(:model_class) { MergeRequest }
        let(:ability) { :read_merge_request }
        let(:merge_request) { create(:merge_request, source_project: accessible_project, author: user) }
        let(:search) { merge_request.title }
        let(:results) { subject.search_objects }

        it_behaves_like 'it redacts incorrect results'
      end
    end
  end
end
