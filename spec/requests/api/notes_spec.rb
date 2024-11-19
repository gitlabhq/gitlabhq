# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Notes, feature_category: :team_planning do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, :public) }
  let(:private_user) { create(:user) }

  before do
    project.add_reporter(user)
  end

  context 'when there are cross-reference system notes' do
    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes" }
    let(:notes_in_response) { json_response }

    it_behaves_like 'with cross-reference system notes'
  end

  context "when noteable is an Issue" do
    let!(:issue) { create(:issue, project: project, author: user) }
    let!(:issue_note) { create(:note, noteable: issue, project: project, author: user) }

    it_behaves_like "noteable API with confidential notes", 'projects', 'issues', 'iid' do
      let(:parent) { project }
      let(:noteable) { issue }
      let(:note) { issue_note }
    end

    context 'when user does not have access to create noteable' do
      let(:private_issue) { create(:issue, project: create(:project, :private)) }

      ##
      # We are posting to project user has access to, but we use issue id
      # from a different project, see #15577
      #
      before do
        post api("/projects/#{private_issue.project.id}/issues/#{private_issue.iid}/notes", user),
          params: { body: 'Hi!' }
      end

      it 'responds with resource not found error' do
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not create new note' do
        expect(private_issue.notes.reload).to be_empty
      end
    end

    context 'when system note with issue_email_participants action' do
      let!(:email) { 'user@example.com' }
      let!(:note_text) { "added #{email}" }
      let!(:note) do
        create(:note, :system, project: project, noteable: issue, author: Users::Internal.support_bot, note: note_text)
      end

      let!(:system_note_metadata) { create(:system_note_metadata, note: note, action: :issue_email_participants) }
      let!(:another_user) { create(:user) }

      let(:obfuscated_email) { 'us*****@e*****.c**' }

      it 'returns obfuscated email' do
        get api("/projects/#{project.id}/issues/#{issue.iid}/notes", another_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.first['body']).to include(obfuscated_email)
      end

      context 'when user has at least the reporter role in project' do
        it 'returns email' do
          get api("/projects/#{project.id}/issues/#{issue.iid}/notes", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response.first['body']).to include(email)
        end
      end
    end

    context "when referencing other project" do
      # For testing the cross-reference of a private issue in a public project
      let(:private_project) do
        create(:project, namespace: private_user.namespace)
        .tap { |p| p.add_maintainer(private_user) }
      end

      let(:private_issue) { create(:issue, project: private_project) }

      let(:ext_proj)  { create(:project, :public) }
      let(:ext_issue) { create(:issue, project: ext_proj) }

      let!(:cross_reference_note) do
        create(
          :note,
          noteable: ext_issue, project: ext_proj,
          note: "mentioned in issue #{private_issue.to_reference(ext_proj)}",
          system: true
        )
      end

      describe "GET /projects/:id/noteable/:noteable_id/notes" do
        context "current user cannot view the notes" do
          it "returns an empty array", :aggregate_failures do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes", user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response).to be_empty
          end

          context "issue is confidential" do
            before do
              ext_issue.update!(confidential: true)
            end

            it "returns 404" do
              get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes", user)

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context "current user can view the note" do
          it "returns a non-empty array", :aggregate_failures do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes", private_user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.first['body']).to eq(cross_reference_note.note)
          end
        end

        context "activity filters" do
          let!(:user_reference_note) do
            create(
              :note,
              noteable: ext_issue, project: ext_proj,
              note: "Hello there general!",
              system: false
            )
          end

          let(:test_url) { "/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes" }

          shared_examples 'a notes request' do
            it 'is a note array response', :aggregate_failures do
              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).to be_an Array
            end
          end

          context "when not provided" do
            let(:count) { 2 }

            before do
              get api(test_url, private_user)
            end

            it_behaves_like 'a notes request'

            it 'returns all the notes' do
              expect(json_response.count).to eq(count)
            end
          end

          context "when all_notes provided" do
            let(:count) { 2 }

            before do
              get api(test_url + "?activity_filter=all_notes", private_user)
            end

            it_behaves_like 'a notes request'

            it 'returns all the notes' do
              expect(json_response.count).to eq(count)
            end
          end

          context "when provided" do
            using RSpec::Parameterized::TableSyntax

            where(:filter, :count, :system_notable) do
              "only_comments" | 1  | false
              "only_activity" | 1  | true
            end

            with_them do
              before do
                get api(test_url + "?activity_filter=#{filter}", private_user)
              end

              it_behaves_like 'a notes request'

              it "properly filters the returned notables", :aggregate_failures do
                expect(json_response.count).to eq(count)
                expect(json_response.first["system"]).to be system_notable
              end
            end
          end
        end
      end

      describe "GET /projects/:id/noteable/:noteable_id/notes/:note_id" do
        context "current user cannot view the notes" do
          it "returns a 404 error" do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes/#{cross_reference_note.id}", user)

            expect(response).to have_gitlab_http_status(:not_found)
          end

          context "when issue is confidential" do
            before do
              issue.update!(confidential: true)
            end

            it "returns 404" do
              get api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{issue_note.id}", private_user)

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context "current user can view the note" do
          it "returns an issue note by id", :aggregate_failures do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes/#{cross_reference_note.id}", private_user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['body']).to eq(cross_reference_note.note)
          end
        end
      end

      context 'without notes widget' do
        let(:request_body) { 'Hi!' }
        let(:params) { { body: request_body } }
        let(:request_path) { "/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes" }

        before do
          WorkItems::Type.default_by_type(:issue).widget_definitions.find_by_widget_type(:notes).update!(disabled: true)
        end

        it 'does not fetch notes' do
          get api(request_path, private_user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'does not fetch specific note' do
          get api("#{request_path}/#{cross_reference_note.id}", private_user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'does not create note' do
          post api(request_path, private_user), params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'does not update note' do
          put api("#{request_path}/#{cross_reference_note.id}", private_user), params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'does not run quick actions' do
          params[:body] = "/spend 1h"

          expect do
            post api("#{request_path}/#{cross_reference_note.id}", private_user), params: params
          end.to not_change { Note.system.count }.and(not_change { Note.where(system: false).count })

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  context "when noteable is a Snippet" do
    let!(:snippet) { create(:project_snippet, project: project, author: user) }
    let!(:snippet_note) { create(:note, noteable: snippet, project: project, author: user) }

    it_behaves_like "noteable API", 'projects', 'snippets', 'id' do
      let(:parent) { project }
      let(:noteable) { snippet }
      let(:note) { snippet_note }
    end
  end

  context "when noteable is a Merge Request" do
    let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }
    let!(:merge_request_note) { create(:note, noteable: merge_request, project: project, author: user) }

    it_behaves_like "noteable API", 'projects', 'merge_requests', 'iid' do
      let(:parent) { project }
      let(:noteable) { merge_request }
      let(:note) { merge_request_note }
    end

    let(:request_body) { 'Hi!' }
    let(:params) { { body: request_body } }
    let(:request_path) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes" }

    subject { post api(request_path, user), params: params }

    context 'a note with both text and invalid command' do
      let(:request_body) { "hello world\n/spend hello" }

      before do
        project.add_developer(user)
      end

      it 'returns 200 status' do
        subject

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'creates a new note' do
        expect { subject }.to change { Note.where(system: false).count }.by(1)
      end

      it 'does not create a system note about the change', :sidekiq_inline do
        expect { subject }.not_to change { Note.system.count }
      end

      it 'does not apply the commands' do
        expect { subject }.not_to change { merge_request.reset.total_time_spent }
      end
    end

    context 'a blank note' do
      let(:request_body) { "" }

      before do
        project.add_developer(user)
      end

      it 'returns a 400 and does not create a note' do
        expect { subject }.not_to change { Note.where(system: false).count }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'an invalid command-only note' do
      let(:request_body) { "/spend asdf" }

      before do
        project.add_developer(user)
      end

      it 'returns a 400 and does not create a note' do
        expect { subject }.not_to change { Note.where(system: false).count }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'does not apply the command' do
        expect { subject }.not_to change { merge_request.reset.total_time_spent }
      end

      it 'reports the errors' do
        subject

        expect(json_response).to eq({ "message" => "400 Bad request - Failed to apply commands." })
      end
    end

    context 'a command only note' do
      context '/spend' do
        let(:request_body) { "/spend 1h" }

        before do
          project.add_developer(user)
        end

        it 'returns 202 Accepted status' do
          subject

          expect(response).to have_gitlab_http_status(:accepted)
        end

        it 'does not actually create a new note' do
          expect { subject }.not_to change { Note.where(system: false).count }
        end

        it 'does however create a system note about the change', :sidekiq_inline do
          expect { subject }.to change { Note.system.count }.by(1)
        end

        it 'applies the commands' do
          expect { subject }.to change { merge_request.reset.total_time_spent }
        end

        it 'reports the changes' do
          subject

          expect(json_response).to include(
            'commands_changes' => include(
              'spend_time' => include('duration' => 3600)
            ),
            'summary' => include('Added 1h spent time.')
          )
        end
      end

      context '/merge' do
        let(:request_body) { "/merge" }
        let(:project) { create(:project, :public, :repository) }
        let(:merge_request) { create(:merge_request_with_multiple_diffs, source_project: project, target_project: project, author: user) }
        let(:params) { { body: request_body, merge_request_diff_head_sha: merge_request.diff_head_sha } }

        before do
          project.add_developer(user)
        end

        it 'returns 202 Accepted status' do
          subject

          expect(response).to have_gitlab_http_status(:accepted)
        end

        it 'does not actually create a new note' do
          expect { subject }.not_to change { Note.where(system: false).count }
        end

        it 'applies the commands' do
          expect { subject }.to change { merge_request.reload.merge_jid.present? }.from(false).to(true)
        end

        it 'reports the changes' do
          subject

          expect(json_response).to include(
            'commands_changes' => include(
              'merge' => merge_request.diff_head_sha
            ),
            'summary' => ['Merged this merge request.']
          )
        end
      end
    end

    context 'when the merge request discussion is locked' do
      before do
        merge_request.update_attribute(:discussion_locked, true)
      end

      context 'when a user is a team member' do
        it 'returns 200 status' do
          subject

          expect(response).to have_gitlab_http_status(:created)
        end

        it 'creates a new note' do
          expect { subject }.to change { Note.count }.by(1)
        end
      end

      context 'when a user is not a team member' do
        subject { post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes", private_user), params: { body: 'Hi!' } }

        it 'returns 403 status' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'does not create a new note' do
          expect { subject }.not_to change { Note.count }
        end
      end
    end

    context 'when authenticated with a token that has the ai_workflows scope' do
      let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

      context 'a post request creates a merge request note' do
        subject { post api(request_path, oauth_access_token: oauth_token), params: params }

        it 'is successful' do
          subject

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'a get request returns a list of merge request notes' do
        subject { get api(request_path, oauth_access_token: oauth_token) }

        it 'is successful' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
