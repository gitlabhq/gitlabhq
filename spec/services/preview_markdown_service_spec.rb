# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PreviewMarkdownService, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
  end

  describe 'user references' do
    let(:params) { { text: "Take a look #{user.to_reference}" } }
    let(:service) { described_class.new(project, user, params) }

    it 'returns users referenced in text' do
      result = service.execute

      expect(result[:users]).to eq [user.username]
    end
  end

  describe 'suggestions' do
    let(:merge_request) do
      create(:merge_request, target_project: project, source_project: project)
    end

    let(:text) { "```suggestion\nfoo\n```" }
    let(:params) do
      suggestion_params.merge(text: text,
                              target_type: 'MergeRequest',
                              target_id: merge_request.iid)
    end

    let(:service) { described_class.new(project, user, params) }

    context 'when preview markdown param is present' do
      let(:path) { "files/ruby/popen.rb" }
      let(:line) { 10 }
      let(:diff_refs) { merge_request.diff_refs }

      let(:suggestion_params) do
        {
          preview_suggestions: true,
          file_path: path,
          line: line,
          base_sha: diff_refs.base_sha,
          start_sha: diff_refs.start_sha,
          head_sha: diff_refs.head_sha
        }
      end

      it 'returns suggestions referenced in text' do
        position = Gitlab::Diff::Position.new(new_path: path,
                                              new_line: line,
                                              diff_refs: diff_refs)

        expect(Gitlab::Diff::SuggestionsParser)
          .to receive(:parse)
          .with(text, position: position,
                      project: merge_request.project,
                      supports_suggestion: true)
          .and_call_original

        result = service.execute

        expect(result[:suggestions]).to all(be_a(Gitlab::Diff::Suggestion))
      end

      context 'when user is not authorized' do
        let(:another_user) { create(:user) }
        let(:service) { described_class.new(project, another_user, params) }

        before do
          project.add_guest(another_user)
        end

        it 'returns no suggestions' do
          result = service.execute

          expect(result[:suggestions]).to be_empty
        end
      end
    end

    context 'when preview markdown param is not present' do
      let(:suggestion_params) do
        {
          preview_suggestions: false
        }
      end

      it 'returns suggestions referenced in text' do
        result = service.execute

        expect(result[:suggestions]).to eq([])
      end
    end
  end

  context 'new note with quick actions' do
    let(:issue) { create(:issue, project: project) }
    let(:params) do
      {
        text: "Please do it\n/assign #{user.to_reference}",
        target_type: 'Issue',
        target_id: issue.id
      }
    end

    let(:service) { described_class.new(project, user, params) }

    it 'removes quick actions from text' do
      result = service.execute

      expect(result[:text]).to eq 'Please do it'
    end

    context 'when render_quick_actions' do
      it 'keeps quick actions' do
        params[:render_quick_actions] = true

        result = service.execute

        expect(result[:text]).to eq "Please do it\n\n/assign #{user.to_reference}"
      end
    end

    it 'explains quick actions effect' do
      result = service.execute

      expect(result[:commands]).to eq "Assigns #{user.to_reference}."
    end
  end

  context 'merge request description' do
    let(:params) do
      {
        text: "My work\n/estimate 2y",
        target_type: 'MergeRequest'
      }
    end

    let(:service) { described_class.new(project, user, params) }

    it 'removes quick actions from text' do
      result = service.execute

      expect(result[:text]).to eq 'My work'
    end

    it 'explains quick actions effect' do
      result = service.execute

      expect(result[:commands]).to eq 'Sets time estimate to 2y.'
    end
  end

  context 'commit description' do
    let(:project) { create(:project, :repository) }
    let(:commit) { project.commit }
    let(:params) do
      {
        text: "My work\n/tag v1.2.3 Stable release",
        target_type: 'Commit',
        target_id: commit.id
      }
    end

    let(:service) { described_class.new(project, user, params) }

    it 'removes quick actions from text' do
      result = service.execute

      expect(result[:text]).to eq 'My work'
    end

    it 'explains quick actions effect' do
      result = service.execute

      expect(result[:commands]).to eq 'Tags this commit to v1.2.3 with "Stable release".'
    end
  end

  context 'note with multiple quick actions' do
    let(:issue) { create(:issue, project: project) }
    let(:params) do
      {
        text: "/confidential\n/due 2001-12-31\n/estimate 2y\n/assign #{user.to_reference}",
        target_type: 'Issue',
        target_id: issue.id
      }
    end

    let(:service) { described_class.new(project, user, params) }

    it 'renders quick actions on multiple lines' do
      result = service.execute

      expect(result[:commands]).to eq "Makes this issue confidential.<br>Sets the due date to Dec 31, 2001.<br>" \
        "Sets time estimate to 2y.<br>Assigns #{user.to_reference}."
    end
  end

  context 'work item quick action types' do
    let(:work_item) { create(:work_item, :task, project: project) }
    let(:params) do
      {
        text: "/title new title",
        target_type: 'WorkItem',
        target_id: work_item.iid
      }
    end

    let(:result) { described_class.new(project, user, params).execute }

    it 'renders the quick action preview' do
      expect(result[:commands]).to eq "Changes the title to \"new title\"."
    end
  end
end
