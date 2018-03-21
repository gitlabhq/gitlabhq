require 'spec_helper'

describe GroupChildEntity do
  include Gitlab::Routing.url_helpers

  let(:user) { create(:user) }
  let(:request) { double('request') }
  let(:entity) { described_class.new(object, request: request) }
  subject(:json) { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
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
      create(:project, :with_avatar,
             description: 'Awesomeness')
    end

    before do
      object.add_master(user)
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

    it_behaves_like 'group child json'
  end

  describe 'for a group', :nested_groups do
    let(:description) { 'Awesomeness' }
    let(:object) do
      create(:group, :nested, :with_avatar,
             description: description)
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

    %w[children_count leave_path parent_id number_projects_with_delimiter number_users_with_delimiter project_count subgroup_count].each do |attribute|
      it "includes #{attribute}" do
        expect(json[attribute.to_sym]).to be_present
      end
    end

    it 'allows an owner to leave when there is another one' do
      object.add_owner(create(:user))

      expect(json[:can_leave]).to be_truthy
    end

    it 'has the correct edit path' do
      expect(json[:edit_path]).to eq(edit_group_path(object))
    end

    context 'emoji in description' do
      let(:description) { ':smile:' }

      it 'has the correct markdown_description' do
        expect(json[:markdown_description]).to eq('<p dir="auto"><gl-emoji title="smiling face with open mouth and smiling eyes" data-name="smile" data-unicode-version="6.0">😄</gl-emoji></p>')
      end
    end

    it_behaves_like 'group child json'
  end
end
