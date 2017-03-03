require 'spec_helper'

describe API::V3::AwardEmoji, api: true  do
  include ApiHelpers

  let(:user)            { create(:user) }
  let!(:project)        { create(:empty_project) }
  let(:issue)           { create(:issue, project: project) }
  let!(:award_emoji)    { create(:award_emoji, awardable: issue, user: user) }
  let!(:merge_request)  { create(:merge_request, source_project: project, target_project: project) }
  let!(:downvote)       { create(:award_emoji, :downvote, awardable: merge_request, user: user) }
  let!(:note)           { create(:note, project: project, noteable: issue) }

  before { project.team << [user, :master] }

  describe 'DELETE /projects/:id/awardable/:awardable_id/award_emoji/:award_id' do
    context 'when the awardable is an Issue' do
      it 'deletes the award' do
        expect do
          delete v3_api("/projects/#{project.id}/issues/#{issue.id}/award_emoji/#{award_emoji.id}", user)

          expect(response).to have_http_status(200)
        end.to change { issue.award_emoji.count }.from(1).to(0)
      end

      it 'returns a 404 error when the award emoji can not be found' do
        delete v3_api("/projects/#{project.id}/issues/#{issue.id}/award_emoji/12345", user)

        expect(response).to have_http_status(404)
      end
    end

    context 'when the awardable is a Merge Request' do
      it 'deletes the award' do
        expect do
          delete v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/award_emoji/#{downvote.id}", user)

          expect(response).to have_http_status(200)
        end.to change { merge_request.award_emoji.count }.from(1).to(0)
      end

      it 'returns a 404 error when note id not found' do
        delete v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/notes/12345", user)

        expect(response).to have_http_status(404)
      end
    end

    context 'when the awardable is a Snippet' do
      let(:snippet) { create(:project_snippet, :public, project: project) }
      let!(:award)  { create(:award_emoji, awardable: snippet, user: user) }

      it 'deletes the award' do
        expect do
          delete v3_api("/projects/#{project.id}/snippets/#{snippet.id}/award_emoji/#{award.id}", user)

          expect(response).to have_http_status(200)
        end.to change { snippet.award_emoji.count }.from(1).to(0)
      end
    end
  end

  describe 'DELETE /projects/:id/awardable/:awardable_id/award_emoji/:award_emoji_id' do
    let!(:rocket)  { create(:award_emoji, awardable: note, name: 'rocket', user: user) }

    it 'deletes the award' do
      expect do
        delete v3_api("/projects/#{project.id}/issues/#{issue.id}/notes/#{note.id}/award_emoji/#{rocket.id}", user)

        expect(response).to have_http_status(200)
      end.to change { note.award_emoji.count }.from(1).to(0)
    end
  end
end
