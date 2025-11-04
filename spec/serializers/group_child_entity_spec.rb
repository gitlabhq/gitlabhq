# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupChildEntity, feature_category: :groups_and_projects do
  include ExternalAuthorizationServiceHelpers
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }

  let(:request) { double('request') }
  let(:entity) { described_class.new(object, request: request) }

  subject(:json) { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
    stub_commonmark_sourcepos_disabled
  end

  shared_examples 'group child json' do
    it 'renders json' do
      is_expected.not_to be_nil
    end

    %i[
      id
      full_name
      full_path
      avatar_url
      name
      description
      markdown_description
      visibility
      type
      can_archive
      can_edit
      visibility
      permission
      permission_integer
      relative_path
      web_url
    ].each do |attribute|
      it "includes #{attribute}" do
        expect(json[attribute]).not_to be_nil
      end
    end
  end

  describe 'for a project' do
    let(:object) do
      create(:project, :with_avatar, description: 'Awesomeness')
    end

    before do
      object.add_maintainer(user)
    end

    it 'has the correct type' do
      expect(json[:type]).to eq('project')
    end

    it 'includes the star count' do
      expect(json[:star_count]).to be_present
    end

    it 'has the correct edit path' do
      expect(json[:edit_path]).to eq(edit_project_path(object))
    end

    it 'includes the last activity at' do
      expect(json[:last_activity_at]).to be_present
    end

    it 'includes permission as integer' do
      expect(json[:permission_integer]).to be(40)
    end

    it 'allows an owner to delete the project' do
      object.add_owner(user)

      expect(json[:can_remove]).to be_truthy
    end

    it 'does not allow a maintainer to delete the project' do
      expect(json[:can_remove]).to be_falsy
    end

    it_behaves_like 'group child json'
  end

  describe 'for a group' do
    let(:description) { 'Awesomeness' }
    let(:object) do
      create(:group, :nested, :with_avatar, description: description)
    end

    before do
      object.add_owner(user)
    end

    it 'has the correct type' do
      expect(json[:type]).to eq('group')
    end

    it 'includes permission as integer' do
      expect(json[:permission_integer]).to be(50)
    end

    it 'counts projects and subgroups as children' do
      create(:project, namespace: object)
      create(:group, parent: object)

      expect(json[:children_count]).to eq(2)
    end

    context 'when group has subgroups' do
      before do
        create(:group, parent: object)
      end

      it 'returns has_subgroups as true' do
        expect(json[:has_subgroups]).to be(true)
      end
    end

    context 'when group does not have subgroups' do
      it 'returns has_subgroups as true' do
        expect(json[:has_subgroups]).to be(false)
      end
    end

    it 'returns is_linked_to_subscription as false' do
      expect(json[:is_linked_to_subscription]).to be(false)
    end

    describe 'delayed deletion attributes' do
      let_it_be(:deletion_adjourned_period) { 14 }

      before do
        stub_application_setting(deletion_adjourned_period: deletion_adjourned_period)
      end

      context 'when group is marked for deletion' do
        let_it_be(:date) { Date.new(2025, 4, 14) }
        let_it_be(:group) { create(:group) }
        let_it_be(:subgroup) { create(:group, name: 'subgroup', parent: group) }
        let_it_be(:sub_subgroup) { create(:group, name: 'subsubgroup', parent: subgroup) }
        let_it_be(:project) { create(:project, name: 'project 1', group: group) }
        let_it_be(:deletion_schedule) do
          create(:group_deletion_schedule, group: group, marked_for_deletion_on: date, deleting_user: user)
        end

        it 'returns marked_for_deletion as true for child projects and groups' do
          [group, subgroup, sub_subgroup, project].each do |item|
            expect(described_class.new(item, request: request).as_json[:marked_for_deletion]).to eq(true)
          end
        end

        it 'returns marked_for_deletion_on' do
          expect(described_class.new(group, request: request).as_json[:marked_for_deletion_on]).to eq(date)
        end

        it 'returns is_self_deletion_scheduled as true for top group' do
          expect(described_class.new(group, request: request).as_json[:is_self_deletion_scheduled]).to eq(true)
        end

        it 'returns is_self_deletion_scheduled as false for subgroups' do
          expect(described_class.new(subgroup, request: request).as_json[:is_self_deletion_scheduled]).to eq(false)
        end

        it 'returns permanent_deletion_date as the date the group will be deleted' do
          expect(described_class.new(group, request: request).as_json[:permanent_deletion_date]).to eq((date + deletion_adjourned_period.days).strftime('%F'))
        end
      end

      context 'when group is not marked for deletion' do
        let_it_be(:group) { create(:group) }
        let_it_be(:subgroup) { create(:group, name: 'subgroup', parent: group) }
        let_it_be(:sub_subgroup) { create(:group, name: 'subsubgroup', parent: subgroup) }
        let_it_be(:project) { create(:project, name: 'project 1', group: group) }

        it 'returns marked_for_deletion as false for child projects and groups' do
          [group, subgroup, sub_subgroup, project].each do |item|
            expect(described_class.new(item, request: request).as_json[:marked_for_deletion]).to eq(false)
          end
        end

        it 'returns marked_for_deletion_on as nil' do
          expect(described_class.new(group, request: request).as_json[:marked_for_deletion_on]).to be_nil
        end

        it 'returns permanent_deletion_date as the theoretical date the group will be deleted' do
          expect(described_class.new(group, request: request).as_json[:permanent_deletion_date]).to eq((Date.current + deletion_adjourned_period.days).strftime('%F'))
        end
      end
    end

    describe 'is_self_deletion_in_progress' do
      context 'when group is being deleted' do
        let_it_be(:group) { create(:group, deleted_at: Time.now) }

        it 'returns true' do
          expect(described_class.new(group, request: request).as_json[:is_self_deletion_in_progress]).to be true
        end
      end

      context 'when group is not being deleted' do
        let_it_be(:group) { create(:group) }

        it 'returns false' do
          expect(described_class.new(group, request: request).as_json[:is_self_deletion_in_progress]).to be false
        end
      end
    end

    %w[children_count leave_path parent_id number_users_with_delimiter group_members_count project_count subgroup_count].each do |attribute|
      it "includes #{attribute}" do
        expect(json[attribute.to_sym]).to be_present
      end
    end

    it 'allows an owner to leave when there is another one' do
      object.add_owner(create(:user))

      expect(json[:can_leave]).to be_truthy
    end

    it 'allows an owner to delete the group' do
      expect(json[:can_remove]).to be_truthy
    end

    it 'allows admin to delete the group', :enable_admin_mode do
      allow(request).to receive(:current_user).and_return(create(:admin))

      expect(json[:can_remove]).to be_truthy
    end

    it 'disallows a maintainer to delete the group' do
      object.add_maintainer(user)

      expect(json[:can_remove]).to be_falsy
    end

    it 'has the correct edit path' do
      expect(json[:edit_path]).to eq(edit_group_path(object))
    end

    context 'emoji in description' do
      let(:description) { ':smile:' }

      it 'has the correct markdown_description' do
        expect(json[:markdown_description]).to eq('<p dir="auto"><gl-emoji title="grinning face with smiling eyes" data-name="smile" data-unicode-version="6.0">😄</gl-emoji></p>')
      end
    end

    it_behaves_like 'group child json'
  end

  describe 'for a private group' do
    let(:object) do
      create(:group, :private)
    end

    describe 'user is member of the group' do
      before do
        object.add_owner(user)
      end

      it 'includes the counts' do
        expect(json.keys).to include(*%i[project_count subgroup_count])
      end
    end

    describe 'user is not a member of the group' do
      it 'does not include the counts' do
        expect(json.keys).not_to include(*%i[project_count subgroup_count])
      end
    end

    describe 'user is only a member of a project in the group' do
      let(:project) { create(:project, namespace: object) }

      before do
        project.add_guest(user)
      end

      it 'does not include the counts' do
        expect(json.keys).not_to include(*%i[project_count subgroup_count])
      end
    end
  end

  describe 'for a project with external authorization enabled' do
    let(:object) do
      create(:project, :with_avatar, description: 'Awesomeness')
    end

    before do
      enable_external_authorization_service_check
      object.add_maintainer(user)
    end

    it 'does not hit the external authorization service' do
      expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

      expect(json[:can_edit]).to eq(false)
    end
  end

  describe 'archived attribute' do
    describe 'for a project' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:project) { create(:project, namespace: group) }

      let(:object) { project }

      before_all do
        project.add_maintainer(user)
      end

      context 'when project is archived' do
        before_all do
          project.update!(archived: true)
        end

        it 'returns archived as true' do
          expect(json[:archived]).to be(true)
        end
      end

      context 'when project is not archived but parent group is archived' do
        before_all do
          group.update!(archived: true)
        end

        it 'returns archived as true' do
          expect(json[:archived]).to be(true)
        end
      end

      context 'when project and parent group are not archived' do
        it 'returns archived as false' do
          expect(json[:archived]).to be(false)
        end
      end
    end

    describe 'for a group' do
      let_it_be_with_reload(:parent_group) { create(:group) }
      let_it_be_with_reload(:group) { create(:group, parent: parent_group) }

      let(:object) { group }

      before_all do
        group.add_owner(user)
      end

      context 'when group is archived' do
        before_all do
          group.update!(archived: true)
        end

        it 'returns archived as true' do
          expect(json[:archived]).to be(true)
        end
      end

      context 'when group is not archived but parent group is archived' do
        before_all do
          parent_group.update!(archived: true)
        end

        it 'returns archived as true' do
          expect(json[:archived]).to be(true)
        end
      end

      context 'when group and its ancestors are not archived' do
        it 'returns archived as false' do
          expect(json[:archived]).to be(false)
        end
      end
    end
  end

  describe 'is_self_archived attribute' do
    describe 'for a project' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:project) { create(:project, namespace: group) }

      let(:object) { project }

      before_all do
        project.add_maintainer(user)
      end

      context 'when project is archived' do
        before_all do
          project.update!(archived: true)
        end

        it 'returns is_self_archived as true' do
          expect(json[:is_self_archived]).to be(true)
        end
      end

      context 'when project is not archived but parent group is archived' do
        before_all do
          group.update!(archived: true)
        end

        it 'returns is_self_archived as false' do
          expect(json[:is_self_archived]).to be(false)
        end
      end

      context 'when project and parent group are not archived' do
        it 'returns is_self_archived as false' do
          expect(json[:is_self_archived]).to be(false)
        end
      end
    end

    describe 'for a group' do
      let_it_be_with_reload(:parent_group) { create(:group) }
      let_it_be_with_reload(:group) { create(:group, parent: parent_group) }

      let(:object) { group }

      before_all do
        group.add_owner(user)
      end

      context 'when group is archived' do
        before_all do
          group.update!(archived: true)
        end

        it 'returns is_self_archived as true' do
          expect(json[:is_self_archived]).to be(true)
        end
      end

      context 'when group is not archived but parent group is archived' do
        before_all do
          parent_group.update!(archived: true)
        end

        it 'returns is_self_archived as false' do
          expect(json[:is_self_archived]).to be(false)
        end
      end

      context 'when group and its ancestors are not archived' do
        it 'returns is_self_archived as false' do
          expect(json[:is_self_archived]).to be(false)
        end
      end
    end
  end

  describe 'can_archive attribute' do
    subject { json[:can_archive] }

    shared_examples 'archive permission attribute' do
      context 'when user has archive permission' do
        before do
          object.add_owner(user)
        end

        it { is_expected.to be(true) }
      end

      context 'when user does not have archive permission' do
        before do
          object.add_guest(user)
        end

        it { is_expected.to be(false) }
      end

      context 'when user is not a member' do
        it { is_expected.to be(false) }
      end

      context 'when current_user is nil' do
        before do
          allow(request).to receive(:current_user).and_return(nil)
        end

        it { is_expected.to be(false) }
      end

      context 'when request does not respond to current_user' do
        before do
          allow(request).to receive(:respond_to?).with(:current_user).and_return(false)
        end

        it { is_expected.to be(false) }
      end
    end

    describe 'for a project' do
      let_it_be_with_reload(:project) { create(:project) }
      let(:object) { project }

      include_examples 'archive permission attribute'
    end

    describe 'for a group' do
      let_it_be_with_reload(:group) { create(:group) }
      let(:object) { group }

      include_examples 'archive permission attribute'
    end
  end
end
