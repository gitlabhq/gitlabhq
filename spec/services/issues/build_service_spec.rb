require 'spec_helper.rb'

describe Issues::BuildService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
  end

  context 'for a single discussion' do
    describe '#execute' do
      let(:merge_request) { create(:merge_request, title: "Hello world", source_project: project) }
      let(:discussion) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, note: "Almost done").to_discussion }
      let(:service) { described_class.new(project, user, merge_request_to_resolve_discussions_of: merge_request.iid, discussion_to_resolve: discussion.id) }

      it 'references the noteable title in the issue title' do
        issue = service.execute

        expect(issue.title).to include('Hello world')
      end

      it 'adds the note content to the description' do
        issue = service.execute

        expect(issue.description).to include('Almost done')
      end
    end
  end

  context 'for discussions in a merge request' do
    let(:merge_request) { create(:merge_request_with_diff_notes, source_project: project) }
    let(:issue) { described_class.new(project, user, merge_request_to_resolve_discussions_of: merge_request.iid).execute }

    describe '#items_for_discussions' do
      it 'has an item for each discussion' do
        create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.source_project, line_number: 13)
        service = described_class.new(project, user, merge_request_to_resolve_discussions_of: merge_request.iid)

        service.execute

        expect(service.items_for_discussions.size).to eq(2)
      end
    end

    describe '#item_for_discussion' do
      let(:service) { described_class.new(project, user, merge_request_to_resolve_discussions_of: merge_request.iid) }

      it 'mentions the author of the note' do
        discussion = create(:diff_note_on_merge_request, author: create(:user, username: 'author')).to_discussion
        expect(service.item_for_discussion(discussion)).to include('@author')
      end

      it 'wraps the note in a blockquote' do
        note_text = "This is a string\n"\
                    ">>>\n"\
                    "with a blockquote\n"\
                    "> That has a quote\n"\
                    ">>>\n"
        note_result = "    > This is a string\n"\
                      "    > > with a blockquote\n"\
                      "    > > > That has a quote\n"
        discussion = create(:diff_note_on_merge_request, note: note_text).to_discussion
        expect(service.item_for_discussion(discussion)).to include(note_result)
      end
    end

    describe '#execute' do
      it 'has the merge request reference in the title' do
        expect(issue.title).to include(merge_request.title)
      end

      it 'has the reference of the merge request in the description' do
        expect(issue.description).to include(merge_request.to_reference)
      end

      it 'does not assign title when a title was given' do
        issue = described_class.new(project, user,
                                    merge_request_to_resolve_discussions_of: merge_request,
                                    title: 'What an issue').execute

        expect(issue.title).to eq('What an issue')
      end

      it 'does not assign description when a description was given' do
        issue = described_class.new(project, user,
                                    merge_request_to_resolve_discussions_of: merge_request,
                                    description: 'Fix at your earliest conveignance').execute

        expect(issue.description).to eq('Fix at your earliest conveignance')
      end

      describe 'with multiple discussions' do
        let!(:diff_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.target_project, line_number: 15) }

        it 'mentions all the authors in the description' do
          authors = merge_request.resolvable_discussions.map(&:author)

          expect(issue.description).to include(*authors.map(&:to_reference))
        end

        it 'has a link for each unresolved discussion in the description' do
          notes = merge_request.resolvable_discussions.map(&:first_note)
          links = notes.map { |note| Gitlab::UrlBuilder.build(note) }

          expect(issue.description).to include(*links)
        end

        it 'mentions additional notes' do
          create_list(:diff_note_on_merge_request, 2, noteable: merge_request, project: merge_request.target_project, in_reply_to: diff_note)

          expect(issue.description).to include('(+2 comments)')
        end
      end
    end
  end

  context 'For a merge request without discussions' do
    let(:merge_request) { create(:merge_request, source_project: project) }

    describe '#execute' do
      it 'mentions the merge request in the description' do
        issue = described_class.new(project, user, merge_request_to_resolve_discussions_of: merge_request.iid).execute

        expect(issue.description).to include("Review the conversation in #{merge_request.to_reference}")
      end
    end
  end

  describe '#execute' do
    let(:milestone) { create(:milestone, project: project) }

    it 'builds a new issues with given params' do
      issue = described_class.new(
        project,
        user,
        title: 'Issue #1',
        description: 'Issue description',
        milestone_id: milestone.id
      ).execute

      expect(issue.title).to eq('Issue #1')
      expect(issue.description).to eq('Issue description')
      expect(issue.milestone).to eq(milestone)
    end
  end
end
