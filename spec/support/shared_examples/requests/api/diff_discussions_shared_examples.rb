# frozen_string_literal: true

RSpec.shared_examples 'diff discussions API' do |parent_type, noteable_type, id_name|
  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions" do
    it "includes diff discussions" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user)

      discussion = json_response.find { |record| record['id'] == diff_note.discussion_id }

      expect(response).to have_gitlab_http_status(:ok)
      expect(discussion).not_to be_nil
      expect(discussion['individual_note']).to eq(false)
      expect(discussion['notes'].first['body']).to eq(diff_note.note)
    end
  end

  describe "GET /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id" do
    it "returns a discussion by id" do
      get api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions/#{diff_note.discussion_id}", user)

      position = diff_note.position.to_h.except(:ignore_whitespace_change)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(diff_note.discussion_id)
      expect(json_response['notes'].first['body']).to eq(diff_note.note)
      expect(json_response['notes'].first['position']).to eq(position.stringify_keys)
      expect(json_response['notes'].first['line_range']).to eq(nil)
    end
  end

  describe "POST /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions" do
    it "creates a new diff note" do
      line_range = {
        "start" => {
          "line_code" => Gitlab::Git.diff_line_code(diff_note.position.file_path, 1, 1),
          "type" => diff_note.position.type
        },
        "end" => {
          "line_code" => Gitlab::Git.diff_line_code(diff_note.position.file_path, 2, 2),
          "type" => diff_note.position.type
        }
      }

      position = diff_note.position.to_h.merge({ line_range: line_range }).except(:ignore_whitespace_change)

      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user),
        params: { body: 'hi!', position: position }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['notes'].first['body']).to eq('hi!')
      expect(json_response['notes'].first['type']).to eq('DiffNote')
      expect(json_response['notes'].first['position']).to eq(position.stringify_keys)
    end

    context "when position is invalid" do
      it "returns a 400 bad request error when position is not plausible" do
        position = diff_note.position.to_h.merge(new_line: '100000')

        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user),
          params: { body: 'hi!', position: position }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns a 400 bad request error when the position is not valid for this discussion" do
        position = diff_note.position.to_h.merge(new_line: '588440f66559714280628a4f9799f0c4eb880a4a')

        post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/discussions", user),
          params: { body: 'hi!', position: position }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe "POST /#{parent_type}/:id/#{noteable_type}/:noteable_id/discussions/:discussion_id/notes" do
    it 'adds a new note to the diff discussion' do
      post api("/#{parent_type}/#{parent.id}/#{noteable_type}/#{noteable[id_name]}/"\
               "discussions/#{diff_note.discussion_id}/notes", user), params: { body: 'hi!' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['body']).to eq('hi!')
      expect(json_response['type']).to eq('DiffNote')
    end
  end
end
