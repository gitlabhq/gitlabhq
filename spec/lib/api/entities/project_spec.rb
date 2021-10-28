# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::Project do
  let(:project) { create(:project, :public) }
  let(:current_user) { create(:user) }
  let(:options) { { current_user: current_user } }

  let(:entity) do
    ::API::Entities::Project.new(project, options)
  end

  subject(:json) { entity.as_json }

  describe '.shared_with_groups' do
    let(:group) { create(:group, :private) }

    before do
      project.project_group_links.create!(group: group)
    end

    context 'when the current user does not have access to the group' do
      it 'is empty' do
        expect(json[:shared_with_groups]).to be_empty
      end
    end

    context 'when the current user has access to the group' do
      before do
        group.add_guest(current_user)
      end

      it 'contains information about the shared group' do
        expect(json[:shared_with_groups]).to contain_exactly(include(group_id: group.id))
      end
    end
  end
end
