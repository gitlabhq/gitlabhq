require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:owner) { create(:user) }
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  let!(:group_with_ldap_links) do
    group = create(:group)
    group.ldap_group_links.create cn: 'ldap-group1', group_access: Gitlab::Access::MASTER, provider: 'ldap1'
    group.ldap_group_links.create cn: 'ldap-group2', group_access: Gitlab::Access::MASTER, provider: 'ldap2'
    group
  end

  before do
    group_with_ldap_links.add_owner owner
    group_with_ldap_links.add_user user, group_access: Gitlab::Access::DEVELOPER
  end

  describe "POST /groups/:id/ldap_group_links" do
    context "when unauthenticated" do
      it "should return authentication error" do
        post api("/groups/#{group_with_ldap_links.id}/ldap_group_links")
        expect(response.status).to eq 401
      end
    end

    context "when a less priviledged user" do
      it "should not allow less priviledged user to add LDAP group link" do
        expect do
          post api("/groups/#{group_with_ldap_links.id}/ldap_group_links", user),
          cn: 'ldap-group4', group_access: GroupMember::GUEST
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response.status).to eq(403)
      end
    end

    context "when owner of the group" do
      it "should return ok and add ldap group link" do
        expect do
          post api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner),
          cn: 'ldap-group3', group_access: GroupMember::GUEST, provider: 'ldap3'
        end.to change { group_with_ldap_links.ldap_group_links.count }.by(1)

        expect(response.status).to eq(201)
        expect(json_response['cn']).to eq('ldap-group3')
        expect(json_response['group_access']).to eq(GroupMember::GUEST)
        expect(json_response['provider']).to eq('ldap3')
      end

      # TODO: Correct and activate this test once issue #329 is fixed
      xit "should return ok and add ldap group link even if no provider specified" do
        expect do
          post api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner),
          cn: 'ldap-group3', group_access: GroupMember::GUEST
        end.to change { group_with_ldap_links.ldap_group_links.count }.by(1)

        expect(response.status).to eq(201)
        expect(json_response['cn']).to eq('ldap-group3')
        expect(json_response['group_access']).to eq(GroupMember::GUEST)
        expect(json_response['provider']).to eq('ldapmain')
      end

      it "should return error if LDAP group link already exists" do
        post api("//groups/#{group_with_ldap_links.id}/ldap_group_links", owner), provider: 'ldap1', cn: 'ldap-group1', group_access: GroupMember::GUEST
        expect(response.status).to eq(409)
      end

      it "should return a 400 error when cn is not given" do
        post api("//groups/#{group_with_ldap_links.id}/ldap_group_links", owner), group_access: GroupMember::GUEST
        expect(response.status).to eq(400)
      end

      it "should return a 400 error when group access is not given" do
        post api("//groups/#{group_with_ldap_links.id}/ldap_group_links", owner), cn: 'ldap-group3'
        expect(response.status).to eq(400)
      end

      it "should return a 422 error when group access is not known" do
        post api("//groups/#{group_with_ldap_links.id}/ldap_group_links", owner), cn: 'ldap-group3', group_access: 11, provider: 'ldap1'
        expect(response.status).to eq(422)
      end
    end
  end

  describe 'DELETE /groups/:id/ldap_group_links/:cn' do
    context "when unauthenticated" do
      it "should return authentication error" do
        delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1")
        expect(response.status).to eq 401
      end
    end

    context "when a less priviledged user" do
      it "should not remove the LDAP group link" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1", user)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response.status).to eq(403)
      end
    end

    context "when owner of the group" do
      it "should remove ldap group link" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1", owner)
        end.to change { group_with_ldap_links.ldap_group_links.count }.by(-1)

        expect(response.status).to eq(200)
      end

      it "should return 404 if LDAP group cn not used for a LDAP group link" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1356", owner)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response.status).to eq(404)
      end
    end
  end

  describe 'DELETE /groups/:id/ldap_group_links/:provider/:cn' do
    context "when unauthenticated" do
      it "should return authentication error" do
        delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap2/ldap-group2")
        expect(response.status).to eq 401
      end
    end

    context "when a less priviledged user" do
      it "should not remove the LDAP group link" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap2/ldap-group2", user)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response.status).to eq(403)
      end
    end

    context "when owner of the group" do
      it "should return 404 if LDAP group cn not used for a LDAP group link for the specified provider" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap1/ldap-group2", owner)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response.status).to eq(404)
      end

      it "should remove ldap group link" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap2/ldap-group2", owner)
        end.to change { group_with_ldap_links.ldap_group_links.count }.by(-1)

        expect(response.status).to eq(200)
      end
    end
  end

end
