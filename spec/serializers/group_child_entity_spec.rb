# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupChildEntity do
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

    %w[id
       full_name
       avatar_url
       name
       description
       markdown_description
       visibility
       type
       can_edit
       visibility
       permission
       relative_path].each do |attribute|
      it "includes #{attribute}" do
        expect(json[attribute.to_sym]).to be_present
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

    %w[children_count leave_path parent_id number_users_with_delimiter project_count subgroup_count].each do |attribute|
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
end
