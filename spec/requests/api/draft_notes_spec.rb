# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DraftNotes, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }

  let_it_be(:merge_request_note) { create(:note, noteable: merge_request, project: project, author: user) }
  let!(:draft_note_by_current_user) { create(:draft_note, merge_request: merge_request, author: user) }
  let!(:draft_note_by_random_user) { create(:draft_note, merge_request: merge_request) }

  let_it_be(:api_stub) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}" }

  before do
    project.add_developer(user)
  end

  describe "Get a list of merge request draft notes" do
    it "returns 200 OK status" do
      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/draft_notes", user)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it "returns only draft notes authored by the current user" do
      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/draft_notes", user)

      draft_note_ids = json_response.pluck("id")

      expect(draft_note_ids).to include(draft_note_by_current_user.id)
      expect(draft_note_ids).not_to include(draft_note_by_random_user.id)
      expect(draft_note_ids).not_to include(merge_request_note.id)
    end
  end

  describe "Get a single draft note" do
    context "when requesting an existing draft note by the user" do
      before do
        get api(
          "/projects/#{project.id}/merge_requests/#{merge_request.iid}/draft_notes/#{draft_note_by_current_user.id}",
          user
        )
      end

      it "returns 200 OK status" do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it "returns the requested draft note" do
        expect(json_response["id"]).to eq(draft_note_by_current_user.id)
      end

      context "when requesting a non-existent draft note" do
        it "returns a 404 Not Found response" do
          get api(
            "/projects/#{project.id}/merge_requests/#{merge_request.iid}/draft_notes/#{DraftNote.last.id + 1}",
            user
          )

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when requesting an existing draft note by another user" do
        it "returns a 404 Not Found response" do
          get api(
            "/projects/#{project.id}/merge_requests/#{merge_request.iid}/draft_notes/#{draft_note_by_random_user.id}",
            user
          )

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe "delete a draft note" do
    context "when deleting an existing draft note by the user" do
      let!(:deleted_draft_note_id) { draft_note_by_current_user.id }

      before do
        delete api(
          "/projects/#{project.id}/merge_requests/#{merge_request.iid}/draft_notes/#{draft_note_by_current_user.id}",
          user
        )
      end

      it "returns 204 No Content status" do
        expect(response).to have_gitlab_http_status(:no_content)
      end

      it "deletes the specified draft note" do
        expect(DraftNote.exists?(deleted_draft_note_id)).to eq(false)
      end
    end

    context "when deleting a non-existent draft note" do
      it "returns a 404 Not Found" do
        delete api(
          "/projects/#{project.id}/merge_requests/#{merge_request.iid}/draft_notes/#{non_existing_record_id}",
          user
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when deleting a draft note by a different user" do
      it "returns a 404 Not Found" do
        delete api(
          "/projects/#{project.id}/merge_requests/#{merge_request.iid}/draft_notes/#{draft_note_by_random_user.id}",
          user
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "Publishing a draft note" do
    let(:publish_draft_note) do
      put api(
        "#{api_stub}/draft_notes/#{draft_note_by_current_user.id}/publish",
        user
      )
    end

    context "when publishing an existing draft note by the user" do
      it "returns 204 No Content status" do
        publish_draft_note

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it "publishes the specified draft note" do
        expect { publish_draft_note }.to change { Note.count }.by(1)
        expect(DraftNote.exists?(draft_note_by_current_user.id)).to eq(false)
      end
    end

    context "when publishing a non-existent draft note" do
      it "returns a 404 Not Found" do
        put api(
          "#{api_stub}/draft_notes/#{non_existing_record_id}/publish",
          user
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when publishing a draft note by a different user" do
      it "returns a 404 Not Found" do
        put api(
          "#{api_stub}/draft_notes/#{draft_note_by_random_user.id}/publish",
          user
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when DraftNotes::PublishService returns a non-success" do
      it "returns an :internal_server_error and a message" do
        expect_next_instance_of(DraftNotes::PublishService) do |instance|
          expect(instance).to receive(:execute).and_return({ status: :failure, message: "Error message" })
        end

        publish_draft_note

        expect(response).to have_gitlab_http_status(:internal_server_error)
      end
    end
  end
end
