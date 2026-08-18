# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectMembers::AppDataSerializer, feature_category: :groups_and_projects do
  include MembersPresentation

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- MembersFinder counts and member serializers need persisted records
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project, freeze: false) { create(:project, group: create(:group)) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:serializer) { described_class.new(project, current_user: current_user) }

  describe '#app_data' do
    let_it_be(:links, freeze: false) { ::Members::GroupLinksCollection.new([]) }

    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Counted by MembersFinder and serialized with policy checks
    let_it_be(:members) { create_list(:project_member, 2, project: project) }
    let_it_be(:invited) { create_list(:project_member, 2, :invited, project: project) }
    let_it_be(:access_requests) { create_list(:project_member, 2, :access_request, project: project) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    let(:available_roles) do
      Gitlab::Access.options_with_owner.map { |name, access_level| { title: name, value: "static-#{access_level}" } }
    end

    let(:members_collection) { members }

    let(:serializer) do
      described_class.new(
        project,
        current_user: current_user,
        members: present_members(members_collection)
      )
    end

    subject(:app_data) do
      serializer.app_data(
        invited: present_members(invited),
        links: links,
        access_requests: present_members(access_requests),
        pending_members_count: nil
      )
    end

    before_all do
      project.add_maintainer(current_user)
    end

    it 'returns the expected app data' do
      expect(app_data).to include(
        source_id: project.id,
        can_manage_members: true,
        can_manage_access_requests: true,
        group_name: project.group.name,
        group_path: project.group.full_path,
        project_path: project.full_path,
        can_approve_access_requests: true,
        available_roles: available_roles
      )
    end

    it 'sets `members` property that matches json schema' do
      expect(app_data[:user][:members].to_json).to match_schema('members')
    end

    it 'sets `member_path` property' do
      expect(app_data[:user][:member_path])
        .to eq(Gitlab::Routing.url_helpers.project_project_member_path(project, ':id'))
    end

    it 'seeds `direct_members` empty with a `members_path` for lazy fetching' do
      expect(app_data[:direct_members][:members]).to eq([])
      expect(app_data[:direct_members][:members_path])
        .to eq(Gitlab::Routing.url_helpers.project_project_members_path(project, format: :json))
    end

    it 'seeds `direct_members` pagination with the count from the same finder that loads the tab rows' do
      finder_count = MembersFinder
        .new(project, current_user)
        .execute(include_relations: [:direct])
        .non_invite
        .count

      expect(app_data[:direct_members][:pagination][:total_items]).to eq(finder_count)
    end

    context 'when direct members filter params are given' do
      let(:searched_member) { members.first }

      let(:serializer) do
        described_class.new(
          project,
          current_user: current_user,
          members: present_members(members_collection),
          direct_members_filter_params: { search: searched_member.user.name, max_role: nil }
        )
      end

      it 'seeds `direct_members` pagination with the filtered count' do
        expect(app_data[:direct_members][:pagination][:total_items]).to eq(1)
      end
    end

    context 'when pagination is not available' do
      it 'sets `pagination` attribute to expected json' do
        expect(app_data[:invite][:pagination]).to include(
          current_page: nil,
          per_page: nil,
          total_items: 2,
          param_name: nil,
          params: {}
        )
      end
    end

    context 'when pagination is available' do
      let(:members_collection) { Kaminari.paginate_array(members).page(1).per(1) }

      it 'sets `pagination` attribute to expected json' do
        expect(app_data[:user][:pagination]).to match(
          current_page: 1,
          per_page: 1,
          total_items: 2,
          param_name: :page,
          params: { search_groups: nil }
        )
      end
    end

    context 'with group links' do
      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Serialized through the group link entities with policy checks
      let_it_be(:shared_with_group) { create(:group) }
      let_it_be(:project_group_link) { create(:project_group_link, project: project, group: shared_with_group) }
      let_it_be(:group_group_link) { create(:group_group_link, shared_group: shared_with_group) }
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      let_it_be(:links, freeze: false) do
        ::Members::GroupLinksCollection.new([group_group_link, project_group_link])
      end

      it 'sets `group.members` property' do
        serialized_members = GroupLink::ProjectGroupLinkSerializer.new
          .represent(links.project_links, { current_user: current_user, source: project })
        serialized_members += GroupLink::GroupGroupLinkSerializer.new
          .represent(links.group_links, { current_user: current_user, source: project })

        expect(app_data[:group][:members].map(&:as_json)).to eq(serialized_members.map(&:as_json))
      end

      it 'sets `group.pagination` property' do
        expect(app_data[:group][:pagination]).to match(
          current_page: 1,
          per_page: 20,
          total_items: 2,
          param_name: :page,
          params: {}
        )
      end

      it 'sets `member_path` property' do
        expect(app_data[:group][:member_path])
          .to eq(Gitlab::Routing.url_helpers.project_group_link_path(project, ':id'))
      end
    end
  end

  describe '#list_data' do
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Serialized with policy checks against persisted records
    let_it_be(:members) { create_list(:project_member, 2, project: project) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    subject(:list_data) do
      serializer.list_data(
        present_members(Kaminari.paginate_array(members).page(1).per(20)),
        { param_name: :direct_members_page, params: { search_groups: nil } }
      )
    end

    it 'returns the serialized members with pagination and member path' do
      expect(list_data[:members].size).to eq(2)
      expect(list_data[:pagination]).to match(
        current_page: 1,
        per_page: 20,
        total_items: 2,
        param_name: :direct_members_page,
        params: { search_groups: nil }
      )
      expect(list_data[:member_path])
        .to eq(Gitlab::Routing.url_helpers.project_project_member_path(project, ':id'))
    end

    context 'when no scoped members are given' do
      let(:serializer) do
        described_class.new(project, current_user: current_user, members: present_members(members))
      end

      subject(:list_data) { serializer.list_data }

      it 'defaults to the members given at construction' do
        expect(list_data[:members].size).to eq(2)
      end
    end
  end
end
