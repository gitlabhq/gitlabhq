# frozen_string_literal: true

RSpec.shared_examples 'diff draft notes API' do |id_name|
  describe "post /projects/:id/merge_requests/:merge_request_id/draft_notes" do
    it "creates a new diff draft note" do
      line_range = {
        "start" => {
          "line_code" => Gitlab::Git.diff_line_code(draft_note.position.file_path, 1, 1),
          "type" => draft_note.position.type
        },
        "end" => {
          "line_code" => Gitlab::Git.diff_line_code(draft_note.position.file_path, 2, 2),
          "type" => draft_note.position.type
        }
      }

      position = draft_note.position.to_h.merge({ line_range: line_range }).except(:ignore_whitespace_change)

      post api("/projects/#{project.id}/merge_requests/#{merge_request[id_name]}/draft_notes", user),
        params: { note: 'hi!', position: position }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['note']).to eq('hi!')
      expect(json_response['position']).to eq(position.stringify_keys)
    end

    context "when position is invalid" do
      it "returns a 400 bad request error when position is not plausible" do
        position = draft_note.position.to_h.merge(new_line: '100000')

        post api("/projects/#{project.id}/merge_requests/#{merge_request[id_name]}/draft_notes", user),
          params: { body: 'hi!', position: position }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns a 400 bad request error when the position is not valid for this discussion" do
        position = draft_note.position.to_h.merge(new_line: '588440f66559714280628a4f9799f0c4eb880a4a')

        post api("/projects/#{project.id}/merge_requests/#{merge_request[id_name]}/draft_notes", user),
          params: { body: 'hi!', position: position }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe "put /projects/:id/merge_requests/:merge_request_id/draft_notes/:draft_note_id" do
    it "modifies a draft note" do
      line_range = {
        "start" => {
          "line_code" => Gitlab::Git.diff_line_code(draft_note.position.file_path, 3, 3),
          "type" => draft_note.position.type
        },
        "end" => {
          "line_code" => Gitlab::Git.diff_line_code(draft_note.position.file_path, 4, 4),
          "type" => draft_note.position.type
        }
      }

      position = draft_note.position.to_h.merge({ line_range: line_range }).except(:ignore_whitespace_change)

      put api("/projects/#{project.id}/merge_requests/#{merge_request[id_name]}/draft_notes/#{draft_note.id}", user),
        params: { note: 'hola!', position: position }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['note']).to eq('hola!')
      expect(json_response['position']).to eq(position.stringify_keys)
    end

    it "returns bad request for an empty note" do
      line_range = {
        "start" => {
          "line_code" => Gitlab::Git.diff_line_code(draft_note.position.file_path, 3, 3),
          "type" => draft_note.position.type
        },
        "end" => {
          "line_code" => Gitlab::Git.diff_line_code(draft_note.position.file_path, 4, 4),
          "type" => draft_note.position.type
        }
      }

      position = draft_note.position.to_h.merge({ line_range: line_range }).except(:ignore_whitespace_change)

      put api("/projects/#{project.id}/merge_requests/#{merge_request[id_name]}/draft_notes/#{draft_note.id}", user),
        params: { note: '', position: position }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end
end
