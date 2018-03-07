require 'spec_helper'

describe API::Notes do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :public, namespace: user.namespace) }
  let(:private_user)    { create(:user) }

  before do
    project.add_reporter(user)
  end

  context "when noteable is an Issue" do
    let!(:issue) { create(:issue, project: project, author: user) }
    let!(:issue_note) { create(:note, noteable: issue, project: project, author: user) }

    it_behaves_like "noteable API", 'projects', 'issues', 'iid' do
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
             body: 'Hi!'
      end

      it 'responds with resource not found error' do
        expect(response.status).to eq 404
      end

      it 'does not create new note' do
        expect(private_issue.notes.reload).to be_empty
      end
    end

    context "when referencing other project" do
      # For testing the cross-reference of a private issue in a public project
      let(:private_project) do
        create(:project, namespace: private_user.namespace)
        .tap { |p| p.add_master(private_user) }
      end
      let(:private_issue)    { create(:issue, project: private_project) }

      let(:ext_proj)  { create(:project, :public) }
      let(:ext_issue) { create(:issue, project: ext_proj) }

      let!(:cross_reference_note) do
        create :note,
        noteable: ext_issue, project: ext_proj,
        note: "mentioned in issue #{private_issue.to_reference(ext_proj)}",
        system: true
      end

      describe "GET /projects/:id/noteable/:noteable_id/notes" do
        context "current user cannot view the notes" do
          it "returns an empty array" do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes", user)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response).to be_empty
          end

          context "issue is confidential" do
            before do
              ext_issue.update_attributes(confidential: true)
            end

            it "returns 404" do
              get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes", user)

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end

        context "current user can view the note" do
          it "returns an empty array" do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes", private_user)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.first['body']).to eq(cross_reference_note.note)
          end
        end
      end

      describe "GET /projects/:id/noteable/:noteable_id/notes/:note_id" do
        context "current user cannot view the notes" do
          it "returns a 404 error" do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes/#{cross_reference_note.id}", user)

            expect(response).to have_gitlab_http_status(404)
          end

          context "when issue is confidential" do
            before do
              issue.update_attributes(confidential: true)
            end

            it "returns 404" do
              get api("/projects/#{project.id}/issues/#{issue.iid}/notes/#{issue_note.id}", private_user)

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end

        context "current user can view the note" do
          it "returns an issue note by id" do
            get api("/projects/#{ext_proj.id}/issues/#{ext_issue.iid}/notes/#{cross_reference_note.id}", private_user)

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['body']).to eq(cross_reference_note.note)
          end
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

    context 'when the merge request discussion is locked' do
      before do
        merge_request.update_attribute(:discussion_locked, true)
      end

      context 'when a user is a team member' do
        subject { post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes", user), body: 'Hi!' }

        it 'returns 200 status' do
          subject

          expect(response).to have_gitlab_http_status(201)
        end

        it 'creates a new note' do
          expect { subject }.to change { Note.count }.by(1)
        end
      end

      context 'when a user is not a team member' do
        subject { post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/notes", private_user), body: 'Hi!' }

        it 'returns 403 status' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end

        it 'does not create a new note' do
          expect { subject }.not_to change { Note.count }
        end
      end
    end
  end

  context "when noteable is an Epic" do
    let(:group) { create(:group, :public, owner: user) }
    let(:ext_group) { create(:group, :public) }
    let(:epic) { create(:epic, group: group, author: user) }
    let!(:epic_note) { create(:note, noteable: epic, project: project, author: user) }

    before do
      group.add_developer(user)
      stub_licensed_features(epics: true)
    end

    it_behaves_like "noteable API", 'groups', 'epics', 'id' do
      let(:parent) { group }
      let(:noteable) { epic }
      let(:note) { epic_note }
    end
  end
end
