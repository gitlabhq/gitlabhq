# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Invitations do
  let(:maintainer) { create(:user, username: 'maintainer_user') }
  let(:developer) { create(:user) }
  let(:access_requester) { create(:user) }
  let(:stranger) { create(:user) }
  let(:email) { 'email1@example.com' }
  let(:email2) { 'email2@example.com' }

  let(:project) do
    create(:project, :public, creator_id: maintainer.id, namespace: maintainer.namespace) do |project|
      project.add_developer(developer)
      project.add_maintainer(maintainer)
      project.request_access(access_requester)
    end
  end

  let!(:group) do
    create(:group, :public) do |group|
      group.add_developer(developer)
      group.add_owner(maintainer)
      group.request_access(access_requester)
    end
  end

  def invitations_url(source, user)
    api("/#{source.model_name.plural}/#{source.id}/invitations", user)
  end

  shared_examples 'POST /:source_type/:id/invitations' do |source_type|
    context "with :source_type == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          post invitations_url(source, stranger),
               params: { email: email, access_level: Member::MAINTAINER }
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)

              post invitations_url(source, user), params: { email: email, access_level: Member::MAINTAINER }

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end
      end

      context 'when authenticated as a maintainer/owner' do
        context 'and new member is already a requester' do
          it 'does not transform the requester into a proper member' do
            expect do
              post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
                   params: { email: email, access_level: Member::MAINTAINER }

              expect(response).to have_gitlab_http_status(:created)
            end.not_to change { source.members.count }
          end
        end

        it 'invites a new member' do
          expect do
            post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
                 params: { email: email, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.requesters.count }.by(1)
        end

        it 'invites a list of new email addresses' do
          expect do
            email_list = [email, email2].join(',')

            post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
                 params: { email: email_list, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.requesters.count }.by(2)
        end
      end

      context 'access levels' do
        it 'does not create the member if group level is higher' do
          parent = create(:group)

          group.update!(parent: parent)
          project.update!(group: group)
          parent.add_developer(stranger)

          post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
               params: { email: stranger.email, access_level: Member::REPORTER }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['message'][stranger.email]).to eq("Access level should be greater than or equal to Developer inherited membership from group #{parent.name}")
        end

        it 'creates the member if group level is lower' do
          parent = create(:group)

          group.update!(parent: parent)
          project.update!(group: group)
          parent.add_developer(stranger)

          post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
               params: { email: stranger.email, access_level: Member::MAINTAINER }

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'access expiry date' do
        subject do
          post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
               params: { email: email, access_level: Member::DEVELOPER, expires_at: expires_at }
        end

        context 'when set to a date in the past' do
          let(:expires_at) { 2.days.ago.to_date }

          it 'does not create a member' do
            expect do
              subject
            end.not_to change { source.members.count }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['message'][email]).to eq('Expires at cannot be a date in the past')
          end
        end

        context 'when set to a date in the future' do
          let(:expires_at) { 2.days.from_now.to_date }

          it 'invites a member' do
            expect do
              subject
            end.to change { source.requesters.count }.by(1)

            expect(response).to have_gitlab_http_status(:created)
          end
        end
      end

      it "returns a message if member already exists" do
        post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
             params: { email: maintainer.email, access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['message'][maintainer.email]).to eq("Already a member of #{source.name}")
      end

      it 'returns 404 when the email is not valid' do
        post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
             params: { email: '', access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['message']).to eq('Email cannot be blank')
      end

      it 'returns 404 when the email list is not a valid format' do
        post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
             params: { email: 'email1@example.com,not-an-email', access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('email contains an invalid email address')
      end

      it 'returns 400 when email is not given' do
        post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
             params: { access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 400 when access_level is not given' do
        post api("/#{source_type.pluralize}/#{source.id}/invitations", maintainer),
             params: { email: email }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 400 when access_level is not valid' do
        post invitations_url(source, maintainer),
             params: { email: email, access_level: non_existing_record_access_level }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'POST /projects/:id/invitations' do
    it_behaves_like 'POST /:source_type/:id/invitations', 'project' do
      let(:source) { project }
    end
  end

  describe 'POST /groups/:id/invitations' do
    it_behaves_like 'POST /:source_type/:id/invitations', 'group' do
      let(:source) { group }
    end
  end

  shared_examples 'GET /:source_type/:id/invitations' do |source_type|
    context "with :source_type == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get invitations_url(source, stranger) }
      end

      %i[maintainer developer access_requester stranger].each do |type|
        context "when authenticated as a #{type}" do
          it 'returns 200' do
            user = public_send(type)

            get invitations_url(source, user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.size).to eq(0)
          end
        end
      end

      it 'avoids N+1 queries' do
        # Establish baseline
        get invitations_url(source, maintainer)

        control = ActiveRecord::QueryRecorder.new do
          get invitations_url(source, maintainer)
        end

        invite_member_by_email(source, source_type, email, maintainer)

        expect do
          get invitations_url(source, maintainer)
        end.not_to exceed_query_limit(control)
      end

      it 'does not find confirmed members' do
        get invitations_url(source, developer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(0)
        expect(json_response.map { |u| u['id'] }).not_to match_array [maintainer.id, developer.id]
      end

      it 'finds all members with no query string specified' do
        invite_member_by_email(source, source_type, email, developer)
        invite_member_by_email(source, source_type, email2, developer)

        get invitations_url(source, developer), params: { query: '' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers

        expect(json_response).to be_an Array
        expect(json_response.count).to eq(2)
        expect(json_response.map { |u| u['invite_email'] }).to match_array [email, email2]
      end

      it 'finds the invitation by invite_email with query string' do
        invite_member_by_email(source, source_type, email, developer)
        invite_member_by_email(source, source_type, email2, developer)

        get invitations_url(source, developer), params: { query: email }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.count).to eq(1)
        expect(json_response.first['invite_email']).to eq(email)
        expect(json_response.first['created_by_name']).to eq(developer.name)
        expect(json_response.first['user_name']).to eq(nil)
      end

      def invite_member_by_email(source, source_type, email, created_by)
        create(:"#{source_type}_member", invite_token: '123', invite_email: email, source: source, user: nil, created_by: created_by)
      end
    end
  end

  describe 'GET /projects/:id/invitations' do
    it_behaves_like 'GET /:source_type/:id/invitations', 'project' do
      let(:source) { project }
    end
  end

  describe 'GET /groups/:id/invitations' do
    it_behaves_like 'GET /:source_type/:id/invitations', 'group' do
      let(:source) { group }
    end
  end
end
