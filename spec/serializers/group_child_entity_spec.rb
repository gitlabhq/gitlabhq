require 'spec_helper'

describe GroupChildEntity do
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
       path
       full_name
       full_path
       avatar_url
       name
       description
       web_url
       visibility
       type
       can_edit
       visibility
       edit_path
       permission].each do |attribute|
      it "includes #{attribute}" do
        expect(json[attribute.to_sym]).to be_present
      end
    end
  end

  describe 'for a project' do
    set(:object) do
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

    it_behaves_like 'group child json'
  end

  describe 'for a group', :nested_groups do
    set(:object) do
      create(:group, :nested, :with_avatar,
             description: 'Awesomeness')
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

    it_behaves_like 'group child json'
  end
end
