# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Suggestions, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  let(:merge_request) do
    create(:merge_request, source_project: project, target_project: project)
  end

  let(:position) do
    Gitlab::Diff::Position.new(
      old_path: "files/ruby/popen.rb",
      new_path: "files/ruby/popen.rb",
      old_line: nil,
      new_line: 9,
      diff_refs: merge_request.diff_refs
    )
  end

  let(:position2) do
    Gitlab::Diff::Position.new(
      old_path: "files/ruby/popen.rb",
      new_path: "files/ruby/popen.rb",
      old_line: nil,
      new_line: 15,
      diff_refs: merge_request.diff_refs
    )
  end

  let(:diff_note) do
    create(:diff_note_on_merge_request, noteable: merge_request, position: position, project: project)
  end

  let(:diff_note2) do
    create(:diff_note_on_merge_request, noteable: merge_request, position: position2, project: project)
  end

  let(:suggestion) do
    create(:suggestion,
      note: diff_note,
      from_content: "      raise RuntimeError, \"System commands must be given as an array of strings\"\n",
      to_content: "      raise RuntimeError, 'Explosion'\n      # explosion?")
  end

  let(:unappliable_suggestion) do
    create(:suggestion, :unappliable, note: diff_note2)
  end

  describe "PUT /suggestions/:id/apply" do
    let(:url) { "/suggestions/#{suggestion.id}/apply" }

    context 'when successfully applies patch' do
      it 'renders an ok response and returns json content' do
        project.add_maintainer(user)

        put api(url, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response)
          .to include('id', 'from_line', 'to_line', 'appliable', 'applied', 'from_content', 'to_content')
      end
    end

    context 'when a custom commit message is included' do
      it 'renders an ok response and returns json content' do
        project.add_maintainer(user)

        message = "cool custom commit message!"

        put api(url, user), params: { commit_message: message }

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.repository.commit.message).to eq(message)
      end
    end

    context 'when not able to apply patch' do
      let(:url) { "/suggestions/#{unappliable_suggestion.id}/apply" }

      it 'renders a bad request error and returns json content' do
        project.add_maintainer(user)

        put api(url, user)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => "Can't apply as this line was changed in a more recent version." })
      end
    end

    context 'when suggestion is not found' do
      let(:url) { "/suggestions/9999/apply" }

      it 'renders a not found error and returns json content' do
        project.add_maintainer(user)

        put api(url, user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response).to eq({ 'message' => 'Suggestion is not applicable as the suggestion was not found.' })
      end
    end

    context 'when suggestion ID is not valid' do
      let(:url) { "/suggestions/foo-123/apply" }

      it 'renders a not found error and returns json content' do
        project.add_maintainer(user)

        put api(url, user)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'error' => 'id is invalid' })
      end
    end

    context 'when unauthorized' do
      it 'renders a forbidden error and returns json content' do
        project.add_reporter(user)

        put api(url, user)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response).to eq({ 'message' => '403 Forbidden' })
      end
    end
  end

  describe "PUT /suggestions/batch_apply" do
    let(:suggestion2) do
      create(
        :suggestion,
        note: diff_note2,
        from_content: "      \"PWD\" => path\n",
        to_content: "      *** FOO ***\n"
      )
    end

    let(:url) { "/suggestions/batch_apply" }

    context 'when successfully applies multiple patches as a batch' do
      before do
        project.add_maintainer(user)
      end

      it 'renders an ok response and returns json content' do
        put api(url, user), params: { ids: [suggestion.id, suggestion2.id] }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to all(
          include('id', 'from_line', 'to_line', 'appliable', 'applied', 'from_content', 'to_content')
        )
      end

      it 'provides a custom commit message' do
        message = "cool custom commit message!"

        put api(url, user), params: { ids: [suggestion.id, suggestion2.id],
                                      commit_message: message }

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.repository.commit.message).to eq(message)
      end
    end

    context 'when not able to apply one or more of the patches' do
      it 'renders a bad request error and returns json content' do
        project.add_maintainer(user)

        put api(url, user), params: { ids: [suggestion.id, unappliable_suggestion.id] }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => "Can't apply as this line was changed in a more recent version." })
      end
    end

    context 'with missing suggestions' do
      it 'renders a not found error and returns json content if any suggestion is not found' do
        project.add_maintainer(user)

        put api(url, user), params: { ids: [suggestion.id, 'foo-123'] }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response)
          .to eq({ 'message' => 'Suggestions are not applicable as one or more suggestions were not found.' })
      end

      it 'renders a bad request error and returns json content when no suggestions are provided' do
        project.add_maintainer(user)

        put api(url, user), params: {}

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response)
          .to eq({ 'error' => "ids is missing" })
      end
    end

    context 'when unauthorized' do
      it 'renders a forbidden error and returns json content' do
        project.add_reporter(user)

        put api(url, user), params: { ids: [suggestion.id, suggestion2.id] }

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response).to eq({ 'message' => '403 Forbidden' })
      end
    end
  end
end
