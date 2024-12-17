# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Invitations, feature_category: :user_profile do
  let_it_be(:maintainer) { create(:user, username: 'maintainer_user') }
  let_it_be(:maintainer2) { create(:user, username: 'user-with-maintainer-role') }
  let_it_be(:developer) { create(:user) }
  let_it_be(:access_requester) { create(:user) }
  let_it_be(:stranger) { create(:user) }
  let_it_be(:unconfirmed_stranger) { create(:user, :unconfirmed) }
  let(:email) { 'email1@example.com' }
  let(:email2) { 'email2@example.com' }

  let_it_be(:project, reload: true) do
    create(:project, :public, creator_id: maintainer.id, namespace: maintainer.namespace) do |project|
      project.add_developer(developer)
      project.add_maintainer(maintainer)
      project.request_access(access_requester)
    end
  end

  let_it_be(:group, reload: true) do
    create(:group, :public) do |group|
      group.add_developer(developer)
      group.add_owner(maintainer)
      group.request_access(access_requester)
    end
  end

  def invitations_url(source, user)
    api("/#{source.model_name.plural}/#{source.id}/invitations", user)
  end

  def invite_member_by_email(source, source_type, email, created_by, access_level: :developer)
    create(:"#{source_type}_member", access_level, invite_token: '123', invite_email: email, source: source, user: nil, created_by: created_by)
  end

  shared_examples 'POST /:source_type/:id/invitations' do |source_type|
    context "with :source_type == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          post invitations_url(source, stranger),
            params: { email: email, access_level: Member::MAINTAINER }
        end
      end

      context 'when authenticated as a non-member or member with insufficient membership management rights' do
        context 'when the user does not have rights to manage members' do
          %i[access_requester stranger developer].each do |type|
            context "as a #{type}" do
              it_behaves_like 'a 403 response when user does not have rights to manage members of a specific access level' do
                let(:route) do
                  post invitations_url(source, public_send(type)),
                    params: { email: email, access_level: Member::MAINTAINER }
                end
              end
            end
          end
        end

        context 'when the user has the rights to manage members but tries to manage members with a higher access level' do
          let(:maintainer) { maintainer2 }

          before do
            source.add_maintainer(maintainer)
          end

          context 'when an invitee is added as OWNER' do
            it_behaves_like 'a 403 response when user does not have rights to manage members of a specific access level' do
              let(:route) do
                post invitations_url(source, maintainer),
                  params: { email: email, access_level: Member::OWNER }
              end
            end
          end

          context 'when an access_requester is added as OWNER' do
            it_behaves_like 'a 403 response when user does not have rights to manage members of a specific access level' do
              let(:route) do
                post invitations_url(source, maintainer),
                  params: { user_id: access_requester.email, access_level: Member::OWNER }
              end
            end
          end
        end
      end

      context 'when authenticated as a maintainer/owner' do
        context 'and new member is already a requester' do
          it 'transforms the requester into a proper member' do
            expect do
              post invitations_url(source, maintainer),
                params: { email: access_requester.email, access_level: Member::MAINTAINER }

              expect(response).to have_gitlab_http_status(:created)
            end.to change { source.members.count }.by(1)
          end
        end

        context 'when invitee is already an invited member' do
          it 'updates the member for that email' do
            member = source.add_developer(email)

            expect do
              post invitations_url(source, maintainer),
                params: { email: email, access_level: Member::MAINTAINER }

              expect(response).to have_gitlab_http_status(:created)
            end.to change { member.reset.access_level }.from(Member::DEVELOPER).to(Member::MAINTAINER)
                                                       .and not_change { source.members.invite.count }
          end
        end

        it 'adds a new member by email' do
          expect do
            post invitations_url(source, maintainer),
              params: { email: email, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.invite.count }.by(1)
        end

        it 'adds a new member by confirmed primary email' do
          expect do
            post invitations_url(source, maintainer),
              params: { email: stranger.email, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.non_invite.count }.by(1)
        end

        it 'adds a new member by confirmed secondary email' do
          secondary_email = create(:email, :confirmed, email: 'secondary@example.com', user: stranger)

          expect do
            post invitations_url(source, maintainer),
              params: { email: secondary_email.email, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.non_invite.count }.by(1)
        end

        it 'adds a new member as an invite for unconfirmed primary email' do
          expect do
            post invitations_url(source, maintainer),
              params: { email: unconfirmed_stranger.email, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.invite.count }.by(1).and change { source.members.non_invite.count }.by(0)
        end

        it 'adds a new member as an invite for unconfirmed secondary email' do
          secondary_email = create(:email, email: 'secondary@example.com', user: stranger)

          expect do
            post invitations_url(source, maintainer),
              params: { email: secondary_email.email, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.invite.count }.by(1).and change { source.members.non_invite.count }.by(0)
        end

        it 'adds a new member by user_id' do
          expect do
            post invitations_url(source, maintainer),
              params: { user_id: stranger.id, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.non_invite.count }.by(1)
        end

        it 'adds new members with email and user_id' do
          expect do
            post invitations_url(source, maintainer),
              params: { email: email, user_id: stranger.id, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.invite.count }.by(1).and change { source.members.non_invite.count }.by(1)
        end

        it 'invites a list of new email addresses' do
          expect do
            email_list = [email, email2].join(',')

            post invitations_url(source, maintainer),
              params: { email: email_list, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.invite.count }.by(2)
        end

        it 'invites a list of new email addresses and user ids' do
          expect do
            stranger2 = create(:user)
            email_list = [email, email2].join(',')
            user_id_list = "#{stranger.id},#{stranger2.id}"

            post invitations_url(source, maintainer),
              params: { email: email_list, user_id: user_id_list, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.invite.count }.by(2).and change { source.members.non_invite.count }.by(2)
        end
      end

      context 'access levels' do
        it 'does not create the member if group level is higher' do
          parent = create(:group)

          group.update!(parent: parent)
          project.update!(group: group)
          parent.add_developer(stranger)

          post invitations_url(source, maintainer),
            params: { email: stranger.email, access_level: Member::REPORTER }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['message'][stranger.email])
            .to eq("Access level should be greater than or equal to Developer inherited membership from group #{parent.name}")
        end

        it 'creates the member if group level is lower' do
          parent = create(:group)

          group.update!(parent: parent)
          project.update!(group: group)
          parent.add_developer(stranger)

          post invitations_url(source, maintainer),
            params: { email: stranger.email, access_level: Member::MAINTAINER }

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'access expiry date' do
        subject do
          post invitations_url(source, maintainer),
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
            end.to change { source.members.invite.count }.by(1)

            expect(response).to have_gitlab_http_status(:created)
          end
        end
      end

      context 'with invite_source considerations', :snowplow do
        let(:params) { { email: email, access_level: Member::DEVELOPER } }

        it 'tracks the invite source as api' do
          post invitations_url(source, maintainer), params: params

          expect_snowplow_event(
            category: 'Members::InviteService',
            action: 'create_member',
            label: 'invitations-api',
            property: 'net_new_user',
            user: maintainer
          )
        end

        it 'tracks the invite source from params' do
          post invitations_url(source, maintainer), params: params.merge(invite_source: '_invite_source_')

          expect_snowplow_event(
            category: 'Members::InviteService',
            action: 'create_member',
            label: '_invite_source_',
            property: 'net_new_user',
            user: maintainer
          )
        end
      end

      context 'when adding project bot' do
        let_it_be(:project_bot) { create(:user, :project_bot) }

        before do
          unrelated_project = create(:project)
          unrelated_project.add_maintainer(project_bot)
        end

        it 'returns error' do
          expect do
            post invitations_url(source, maintainer),
              params: { email: project_bot.email, access_level: Member::DEVELOPER }

            expect(json_response['status']).to eq 'error'
            expect(json_response['message'][project_bot.email]).to include('User project bots cannot be added to other groups / projects')
          end.not_to change { source.members.count }
        end
      end

      it "updates an already existing active member" do
        post invitations_url(source, maintainer),
          params: { email: developer.email, access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['status']).to eq("success")
        expect(source.members.find_by(user: developer).access_level).to eq Member::MAINTAINER
      end

      it 'returns 400 when the invite params of email and user_id are not sent' do
        post invitations_url(source, maintainer),
          params: { access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('400 Bad request - Must provide either email or user_id as a parameter')
      end

      it 'returns 400 when the email is blank' do
        post invitations_url(source, maintainer),
          params: { email: '', access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('400 Bad request - Must provide either email or user_id as a parameter')
      end

      it 'returns 400 when the user_id is blank' do
        post invitations_url(source, maintainer),
          params: { user_id: '', access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('400 Bad request - Must provide either email or user_id as a parameter')
      end

      it 'returns 400 when the email list is not a valid format' do
        post invitations_url(source, maintainer),
          params: { email: %w[email1@example.com not-an-email], access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('email contains an invalid email address')
      end

      it 'returns 400 when the comma-separated email list is not a valid format' do
        post invitations_url(source, maintainer),
          params: { email: 'email1@example.com,not-an-email', access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('email contains an invalid email address')
      end

      it 'returns 400 when access_level is not given' do
        post invitations_url(source, maintainer),
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

    it 'does not exceed expected queries count for emails', :request_store, :use_sql_query_cache do
      post invitations_url(project, maintainer), params: { email: email, access_level: Member::DEVELOPER }

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post invitations_url(project, maintainer), params: { email: email2, access_level: Member::DEVELOPER }
      end

      emails = 'email3@example.com,email4@example.com,email5@example.com,email6@example.com,email7@example.com'

      unresolved_n_plus_ones = 40 # currently there are 10 queries added per email

      expect do
        post invitations_url(project, maintainer), params: { email: emails, access_level: Member::DEVELOPER }
      end.not_to exceed_all_query_limit(control).with_threshold(unresolved_n_plus_ones)
    end

    it 'does not exceed expected queries count for user_ids', :request_store, :use_sql_query_cache do
      stranger2 = create(:user)

      post invitations_url(project, maintainer), params: { user_id: stranger.id, access_level: Member::DEVELOPER }

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post invitations_url(project, maintainer), params: { user_id: stranger2.id, access_level: Member::DEVELOPER }
      end

      users = create_list(:user, 5)

      unresolved_n_plus_ones = 136 # 54 for 1 vs 190 for 5 - currently there are 34 queries added per user

      expect do
        post invitations_url(project, maintainer), params: { user_id: users.map(&:id).join(','), access_level: Member::DEVELOPER }
      end.not_to exceed_all_query_limit(control).with_threshold(unresolved_n_plus_ones)
    end

    it 'does not exceed expected queries count with secondary emails', :request_store, :use_sql_query_cache do
      organization = project.organization
      create(:email, :confirmed, email: email, user: create(:user, organizations: [organization]))

      post invitations_url(project, maintainer), params: { email: email, access_level: Member::DEVELOPER }

      create(:email, :confirmed, email: email2, user: create(:user, organizations: [organization]))

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post invitations_url(project, maintainer), params: { email: email2, access_level: Member::DEVELOPER }
      end

      create(:email, :confirmed, email: 'email4@example.com', user: create(:user, organizations: [organization]))
      create(:email, :confirmed, email: 'email6@example.com', user: create(:user, organizations: [organization]))
      create(:email, :confirmed, email: 'email8@example.com', user: create(:user, organizations: [organization]))

      emails = 'email3@example.com,email4@example.com,email5@example.com,email6@example.com,email7@example.com,' \
        'EMAIL8@EXamPle.com'

      unresolved_n_plus_ones = 82 # currently there are 10 queries added per email, checking if we should dispatch AuthorizationsAddedEvent makes 1 query per event (3 events dispatched)

      expect do
        post invitations_url(project, maintainer), params: { email: emails, access_level: Member::DEVELOPER }
      end.not_to exceed_all_query_limit(control).with_threshold(unresolved_n_plus_ones)
    end
  end

  describe 'POST /groups/:id/invitations' do
    it_behaves_like 'POST /:source_type/:id/invitations', 'group' do
      let(:source) { group }
    end

    it 'does not exceed expected queries count for emails', :request_store, :use_sql_query_cache do
      post invitations_url(group, maintainer), params: { email: email, access_level: Member::DEVELOPER }

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post invitations_url(group, maintainer), params: { email: email2, access_level: Member::DEVELOPER }
      end

      emails = 'email3@example.com,email4@example.com,email5@example.com,email6@example.com,email7@example.com'

      unresolved_n_plus_ones = 36 # currently there are 9 queries added per email

      expect do
        post invitations_url(group, maintainer), params: { email: emails, access_level: Member::DEVELOPER }
      end.not_to exceed_all_query_limit(control).with_threshold(unresolved_n_plus_ones)
    end

    it 'does not exceed expected queries count for secondary emails', :request_store, :use_sql_query_cache do
      create(:email, email: email, user: create(:user))

      post invitations_url(group, maintainer), params: { email: email, access_level: Member::DEVELOPER }

      create(:email, email: email2, user: create(:user))

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post invitations_url(group, maintainer), params: { email: email2, access_level: Member::DEVELOPER }
      end

      create(:email, email: 'email4@example.com', user: create(:user))
      create(:email, email: 'email6@example.com', user: create(:user))

      emails = 'email3@example.com,email4@example.com,email5@example.com,email6@example.com,email7@example.com'

      unresolved_n_plus_ones = 56 # currently there are 8 queries added per email

      expect do
        post invitations_url(group, maintainer), params: { email: emails, access_level: Member::DEVELOPER }
      end.not_to exceed_all_query_limit(control).with_threshold(unresolved_n_plus_ones)
    end
  end

  shared_examples 'GET /:source_type/:id/invitations' do |source_type|
    context "with :source_type == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get invitations_url(source, stranger) }
      end

      context "when authenticated as a maintainer" do
        it 'returns 200' do
          get invitations_url(source, maintainer)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(0)
        end
      end

      %i[access_requester stranger developer].each do |type|
        context "as a #{type}" do
          it_behaves_like 'a 403 response when user does not have rights to manage members of a specific access level' do
            let(:route) do
              get invitations_url(source, public_send(type))
            end
          end
        end
      end

      it 'does not find confirmed members' do
        get invitations_url(source, maintainer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(0)
        expect(json_response.map { |u| u['id'] }).not_to match_array [maintainer.id, developer.id]
      end

      it 'finds all members with no query string specified' do
        invite_member_by_email(source, source_type, email, maintainer)
        invite_member_by_email(source, source_type, email2, maintainer)

        get invitations_url(source, maintainer), params: { query: '' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers

        expect(json_response).to be_an Array
        expect(json_response.count).to eq(2)
        expect(json_response.map { |u| u['invite_email'] }).to match_array [email, email2]
      end

      it 'finds the invitation by invite_email with query string' do
        invite_member_by_email(source, source_type, email, maintainer)
        invite_member_by_email(source, source_type, email2, maintainer)

        get invitations_url(source, maintainer), params: { query: email }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.count).to eq(1)
        expect(json_response.first['invite_email']).to eq(email)
        expect(json_response.first['created_by_name']).to eq(maintainer.name)
        expect(json_response.first['user_name']).to eq(nil)
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

  shared_examples 'DELETE /:source_type/:id/invitations/:email' do |source_type|
    def invite_api(source, user, email)
      api("/#{source.model_name.plural}/#{source.id}/invitations/#{email}", user)
    end

    context "with :source_type == #{source_type.pluralize}" do
      let!(:invite) { invite_member_by_email(source, source_type, developer.email, developer) }

      it_behaves_like 'a 404 response when source is private' do
        let(:route) { delete api("/#{source_type.pluralize}/#{source.id}/invitations/#{invite.invite_email}", stranger) }
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        context 'when the user does not have rights to manage members' do
          %i[access_requester stranger].each do |type|
            context "as a #{type}" do
              it_behaves_like 'a 403 response when user does not have rights to manage members of a specific access level' do
                let(:route) do
                  delete invite_api(source, public_send(type), invite.invite_email)
                end
              end
            end
          end
        end
      end

      context 'when authenticated as a member and deleting themself' do
        it 'does not delete the member' do
          expect do
            delete invite_api(source, developer, invite.invite_email)

            expect(response).to have_gitlab_http_status(:forbidden)
          end.not_to change { source.members.count }
        end
      end

      context 'when authenticated as a maintainer/owner' do
        it 'deletes the member and returns 204 with no content' do
          expect do
            delete invite_api(source, maintainer, invite.invite_email)

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { source.members.count }.by(-1)
        end

        context 'when MAINTAINER tries to remove invitation of an OWNER' do
          let_it_be(:maintainer) { maintainer2 }
          let!(:owner_invite) do
            invite_member_by_email(source, source_type, 'owner@owner.com', developer, access_level: :owner)
          end

          before do
            source.add_maintainer(maintainer)
          end

          it_behaves_like 'a 403 response when user does not have rights to manage members of a specific access level' do
            let(:route) do
              delete invite_api(source, maintainer, owner_invite.invite_email)
            end
          end
        end
      end

      it 'returns 404 if member does not exist' do
        delete invite_api(source, maintainer, non_existing_record_id)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 422 for a valid request if the resource was not destroyed' do
        allow_next_instance_of(::Members::DestroyService) do |instance|
          allow(instance).to receive(:execute).with(invite).and_return(invite)
        end

        delete invite_api(source, maintainer, invite.invite_email)

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /projects/:id/inviations/:email' do
    it_behaves_like 'DELETE /:source_type/:id/invitations/:email', 'project' do
      let(:source) { project }
    end
  end

  describe 'DELETE /groups/:id/inviations/:email' do
    it_behaves_like 'DELETE /:source_type/:id/invitations/:email', 'group' do
      let(:source) { group }
    end
  end

  describe 'PUT /groups/:id/invitations' do
    let(:source) { group }

    def update_api(source, user, email)
      api("/#{source.model_name.plural}/#{source.id}/invitations/#{email}", user)
    end

    context "with :source_type == 'groups'" do
      let!(:invite) { invite_member_by_email(source, 'group', developer.email, maintainer) }

      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          put update_api(source, stranger, invite.invite_email), params: { access_level: Member::MAINTAINER }
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        context 'when the user does not have rights to manage members' do
          %i[access_requester stranger].each do |type|
            context "as a #{type}" do
              it_behaves_like 'a 403 response when user does not have rights to manage members of a specific access level' do
                let(:route) do
                  put update_api(source, public_send(type), invite.invite_email),
                    params: { access_level: Member::MAINTAINER }
                end
              end
            end
          end
        end
      end

      context 'when authenticated as a maintainer/owner' do
        context 'updating access level' do
          it 'updates the invitation' do
            put update_api(source, maintainer, invite.invite_email), params: { access_level: Member::MAINTAINER }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['access_level']).to eq(Member::MAINTAINER)
            expect(invite.reload.access_level).to eq(Member::MAINTAINER)
          end

          context 'MAINTAINER tries to update access level to OWNER' do
            let_it_be(:maintainer) { maintainer2 }

            before do
              source.add_maintainer(maintainer)
            end

            it_behaves_like 'a 403 response when user does not have rights to manage members of a specific access level' do
              let(:route) do
                put update_api(source, maintainer, invite.invite_email),
                  params: { access_level: Member::OWNER }
              end
            end
          end
        end

        it 'returns 409 if member does not exist' do
          put update_api(source, maintainer, non_existing_record_id), params: { access_level: Member::MAINTAINER }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 400 when access_level is not given and there are no other params' do
          put update_api(source, maintainer, invite.invite_email)

          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it 'returns 400 when access level is not valid' do
          put update_api(source, maintainer, invite.invite_email), params: { access_level: non_existing_record_access_level }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'updating access expiry date' do
        subject(:put_request) do
          put update_api(source, maintainer, invite.invite_email), params: { expires_at: expires_at }
        end

        context 'when set to a date in the past' do
          let(:expires_at) { 2.days.ago.to_date }

          it 'does not update the member' do
            put_request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq({ 'expires_at' => ['cannot be a date in the past'] })
          end
        end

        context 'when set to a date in the future' do
          let(:expires_at) { 2.days.from_now.to_date }

          it 'updates the member' do
            put_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['expires_at']).to eq(expires_at.to_s)
          end
        end
      end
    end
  end
end
