# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DraftNotes, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, developers: user) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }

  let_it_be(:private_project) { create(:project, :private) }
  let_it_be(:private_merge_request) do
    create(:merge_request, source_project: private_project, target_project: private_project)
  end

  let_it_be(:merge_request_note) { create(:note, noteable: merge_request, project: project, author: user) }
  let!(:draft_note_by_current_user) { create(:draft_note, merge_request: merge_request, author: user) }
  let!(:draft_note_by_random_user) { create(:draft_note, merge_request: merge_request) }

  let_it_be(:base_url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/draft_notes" }

  describe "Get a list of merge request draft notes" do
    it "returns 200 OK status" do
      get api(base_url, user)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it "returns only draft notes authored by the current user",
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448707' do
      get api(base_url, user)

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
          "#{base_url}/#{draft_note_by_current_user.id}",
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
            "#{base_url}/#{DraftNote.last.id + 1}",
            user
          )

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when requesting an existing draft note by another user" do
        it "returns a 404 Not Found response" do
          get api(
            "#{base_url}/#{draft_note_by_random_user.id}",
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
        allow_next_instance_of(DraftNotes::DestroyService) do |service|
          allow(service).to receive(:unfolded_drafts?).and_return(true)
        end

        delete api(
          "#{base_url}/#{draft_note_by_current_user.id}",
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
          "#{base_url}/#{non_existing_record_id}",
          user
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when deleting a draft note by a different user" do
      it "returns a 404 Not Found" do
        delete api(
          "#{base_url}/#{draft_note_by_random_user.id}",
          user
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  def create_draft_note(params = {}, url = base_url)
    post api(url, user), params: params
  end

  describe "Create a new draft note" do
    let(:basic_create_params) do
      {
        note: "Example body string"
      }
    end

    context "when creating a new draft note" do
      context "with required params" do
        it "returns 201 Created status" do
          create_draft_note(basic_create_params)

          expect(response).to have_gitlab_http_status(:created)
        end

        it "creates a new draft note with the submitted params" do
          expect { create_draft_note(basic_create_params) }.to change { DraftNote.count }.by(1)

          expect(json_response["note"]).to eq(basic_create_params[:note])
          expect(json_response["merge_request_id"]).to eq(merge_request.id)
          expect(json_response["author_id"]).to eq(user.id)
        end
      end

      context "without required params" do
        it "returns 400 Bad Request status" do
          create_draft_note({})

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context "when providing a non-existing commit_id" do
        it "returns a 400 Bad Request" do
          create_draft_note(
            basic_create_params.merge(
              commit_id: 'bad SHA'
            )
          )

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context "when targeting a merge request the user doesn't have access to" do
        it "returns a 404 Not Found" do
          create_draft_note(
            basic_create_params,
            "/projects/#{private_project.id}/merge_requests/#{private_merge_request.iid}"
          )

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when using a diff with position" do
        let!(:draft_note) { create(:draft_note_on_text_diff, merge_request: merge_request, author: user) }

        it_behaves_like 'diff draft notes API', 'iid'

        context "when position is for a previous commit on the merge request" do
          it "returns a 400 bad request error because the line_code is old" do
            # SHA taken from an earlier commit listed in spec/factories/merge_requests.rb
            position = draft_note.position.to_h.merge(new_line: 'c1acaa58bbcbc3eafe538cb8274ba387047b69f8')

            post api("/projects/#{project.id}/merge_requests/#{merge_request['iid']}/draft_notes", user),
              params: { body: 'hi!', position: position }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context "when using a diff file position" do
        let!(:draft_note) { create(:draft_note_on_text_diff, merge_request: merge_request, author: user) }

        it "creates a new diff file draft note" do
          position = draft_note.position.to_h.merge(position_type: 'file').except(:ignore_whitespace_change)

          post api("/projects/#{project.id}/merge_requests/#{merge_request['iid']}/draft_notes", user),
            params: { note: 'hi!', position: position }

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context "when attempting to resolve a disscussion" do
        context "when providing a non-existant ID" do
          it "returns a 400 Bad Request" do
            create_draft_note(
              basic_create_params.merge(
                resolve_discussion: true,
                in_reply_to_discussion_id: non_existing_record_id
              )
            )

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context "when not providing an ID" do
          it "returns a 400 Bad Request" do
            create_draft_note(basic_create_params.merge(resolve_discussion: true))

            expect(response).to have_gitlab_http_status(:bad_request)
          end

          it "returns a validation error message" do
            create_draft_note(basic_create_params.merge(resolve_discussion: true))

            expect(response.body)
              .to eq("{\"message\":{\"base\":[\"User is not allowed to resolve thread\"]}}")
          end
        end
      end
    end
  end

  def update_draft_note(params = {}, url = base_url)
    put api("#{url}/#{draft_note_by_current_user.id}", user), params: params
  end

  describe "Update a draft note" do
    let(:basic_update_params) do
      {
        note: "Example updated body string"
      }
    end

    context "when updating an existing draft note" do
      context "with required params" do
        it "returns 200 Success status" do
          update_draft_note(basic_update_params)

          expect(response).to have_gitlab_http_status(:success)
        end

        it "updates draft note with the new content" do
          update_draft_note(basic_update_params)

          expect(json_response["note"]).to eq(basic_update_params[:note])
        end
      end

      context "without including an update to the note body" do
        it "returns the draft note with no changes" do
          expect { update_draft_note({}) }
            .not_to change { draft_note_by_current_user.note }
        end
      end

      context "when updating a non-existent draft note" do
        it "returns a 404 Not Found" do
          put api("#{base_url}/#{non_existing_record_id}", user), params: basic_update_params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when updating a draft note by a different user" do
        it "returns a 404 Not Found" do
          put api("#{base_url}/#{draft_note_by_random_user.id}", user), params: basic_update_params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe "Publishing a draft note" do
    let(:publish_draft_note) do
      put api(
        "#{base_url}/#{draft_note_by_current_user.id}/publish",
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
          "#{base_url}/#{non_existing_record_id}/publish",
          user
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when publishing a draft note by a different user" do
      it "returns a 404 Not Found" do
        put api(
          "#{base_url}/#{draft_note_by_random_user.id}/publish",
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

  describe "Bulk publishing draft notes" do
    let(:bulk_publish_draft_notes) do
      post api(
        "#{base_url}/bulk_publish",
        user
      )
    end

    let!(:draft_note_by_current_user_2) { create(:draft_note, merge_request: merge_request, author: user) }

    context "when publishing an existing draft note by the user" do
      it "returns 204 No Content status" do
        bulk_publish_draft_notes

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it "publishes the specified draft notes" do
        expect { bulk_publish_draft_notes }.to change { Note.count }.by(2)
        expect(DraftNote.exists?(draft_note_by_current_user.id)).to eq(false)
        expect(DraftNote.exists?(draft_note_by_current_user_2.id)).to eq(false)
      end

      it "only publishes the user's draft notes" do
        bulk_publish_draft_notes

        expect(DraftNote.exists?(draft_note_by_random_user.id)).to eq(true)
      end
    end

    context "when DraftNotes::PublishService returns a non-success" do
      it "returns an :internal_server_error and a message" do
        expect_next_instance_of(DraftNotes::PublishService) do |instance|
          expect(instance).to receive(:execute).and_return({ status: :failure, message: "Error message" })
        end

        bulk_publish_draft_notes

        expect(response).to have_gitlab_http_status(:internal_server_error)
      end
    end
  end
end
