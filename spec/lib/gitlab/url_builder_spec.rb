# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UrlBuilder do
  describe '.build' do
    context 'when passing a Commit' do
      it 'returns a proper URL' do
        commit = build_stubbed(:commit)

        url = described_class.build(commit)

        expect(url).to eq "#{Settings.gitlab['url']}/#{commit.project.full_path}/commit/#{commit.id}"
      end
    end

    context 'when passing an Issue' do
      it 'returns a proper URL' do
        issue = build_stubbed(:issue, iid: 42)

        url = described_class.build(issue)

        expect(url).to eq "#{Settings.gitlab['url']}/#{issue.project.full_path}/issues/#{issue.iid}"
      end
    end

    context 'when passing a Milestone' do
      let(:group) { create(:group) }
      let(:project) { create(:project, :public, namespace: group) }

      context 'belonging to a project' do
        it 'returns a proper URL' do
          milestone = create(:milestone, project: project)

          url = described_class.build(milestone)

          expect(url).to eq "#{Settings.gitlab['url']}/#{milestone.project.full_path}/-/milestones/#{milestone.iid}"
        end
      end

      context 'belonging to a group' do
        it 'returns a proper URL' do
          milestone = create(:milestone, group: group)

          url = described_class.build(milestone)

          expect(url).to eq "#{Settings.gitlab['url']}/groups/#{milestone.group.full_path}/-/milestones/#{milestone.iid}"
        end
      end
    end

    context 'when passing a MergeRequest' do
      it 'returns a proper URL' do
        merge_request = build_stubbed(:merge_request, iid: 42)

        url = described_class.build(merge_request)

        expect(url).to eq "#{Settings.gitlab['url']}/#{merge_request.project.full_path}/-/merge_requests/#{merge_request.iid}"
      end
    end

    context 'when passing a ProjectSnippet' do
      it 'returns a proper URL' do
        project_snippet = create(:project_snippet)

        url = described_class.build(project_snippet)

        expect(url).to eq "#{Settings.gitlab['url']}/#{project_snippet.project.full_path}/snippets/#{project_snippet.id}"
      end
    end

    context 'when passing a PersonalSnippet' do
      it 'returns a proper URL' do
        personal_snippet = create(:personal_snippet)

        url = described_class.build(personal_snippet)

        expect(url).to eq "#{Settings.gitlab['url']}/snippets/#{personal_snippet.id}"
      end
    end

    context 'when passing a Note' do
      context 'on a Commit' do
        it 'returns a proper URL' do
          note = build_stubbed(:note_on_commit)

          url = described_class.build(note)

          expect(url).to eq "#{Settings.gitlab['url']}/#{note.project.full_path}/commit/#{note.commit_id}#note_#{note.id}"
        end
      end

      context 'on a Commit Diff' do
        it 'returns a proper URL' do
          note = build_stubbed(:diff_note_on_commit)

          url = described_class.build(note)

          expect(url).to eq "#{Settings.gitlab['url']}/#{note.project.full_path}/commit/#{note.commit_id}#note_#{note.id}"
        end
      end

      context 'on an Issue' do
        it 'returns a proper URL' do
          issue = create(:issue, iid: 42)
          note = build_stubbed(:note_on_issue, noteable: issue)

          url = described_class.build(note)

          expect(url).to eq "#{Settings.gitlab['url']}/#{issue.project.full_path}/issues/#{issue.iid}#note_#{note.id}"
        end
      end

      context 'on a MergeRequest' do
        it 'returns a proper URL' do
          merge_request = create(:merge_request, iid: 42)
          note = build_stubbed(:note_on_merge_request, noteable: merge_request)

          url = described_class.build(note)

          expect(url).to eq "#{Settings.gitlab['url']}/#{merge_request.project.full_path}/-/merge_requests/#{merge_request.iid}#note_#{note.id}"
        end
      end

      context 'on a MergeRequest Diff' do
        it 'returns a proper URL' do
          merge_request = create(:merge_request, iid: 42)
          note = build_stubbed(:diff_note_on_merge_request, noteable: merge_request)

          url = described_class.build(note)

          expect(url).to eq "#{Settings.gitlab['url']}/#{merge_request.project.full_path}/-/merge_requests/#{merge_request.iid}#note_#{note.id}"
        end
      end

      context 'on a ProjectSnippet' do
        it 'returns a proper URL' do
          project_snippet = create(:project_snippet)
          note = build_stubbed(:note_on_project_snippet, noteable: project_snippet)

          url = described_class.build(note)

          expect(url).to eq "#{Settings.gitlab['url']}/#{project_snippet.project.full_path}/snippets/#{note.noteable_id}#note_#{note.id}"
        end
      end

      context 'on a PersonalSnippet' do
        it 'returns a proper URL' do
          personal_snippet = create(:personal_snippet)
          note = build_stubbed(:note_on_personal_snippet, noteable: personal_snippet)

          url = described_class.build(note)

          expect(url).to eq "#{Settings.gitlab['url']}/snippets/#{note.noteable_id}#note_#{note.id}"
        end
      end

      context 'on another object' do
        it 'returns a proper URL' do
          project = build_stubbed(:project)

          expect { described_class.build(project) }
            .to raise_error(NotImplementedError, 'No URL builder defined for Project')
        end
      end
    end

    context 'when passing a WikiPage' do
      it 'returns a proper URL' do
        wiki_page = build(:wiki_page)
        url = described_class.build(wiki_page)

        expect(url).to eq "#{Gitlab.config.gitlab.url}#{wiki_page.wiki.wiki_base_path}/#{wiki_page.slug}"
      end
    end
  end
end
