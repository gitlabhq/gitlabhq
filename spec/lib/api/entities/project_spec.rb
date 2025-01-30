# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::Project do
  let(:project) { create(:project, :public) }
  let(:current_user) { create(:user) }
  let(:options) { { current_user: current_user } }

  let(:entity) do
    described_class.new(project, options)
  end

  subject(:json) { entity.as_json }

  context 'without project feature' do
    before do
      project.project_feature.destroy!
      project.reload
    end

    it 'returns a response' do
      expect(json[:issues_access_level]).to be_nil
      expect(json[:repository_access_level]).to be_nil
      expect(json[:merge_requests_access_level]).to be_nil
    end
  end

  describe '.service_desk_address', feature_category: :service_desk do
    before do
      allow(::ServiceDesk).to receive(:enabled?).and_return(true)
    end

    context 'when a user can admin issues' do
      before do
        project.add_reporter(current_user)
      end

      it 'is present' do
        expect(json[:service_desk_address]).to be_present
      end
    end

    context 'when a user can not admin project' do
      it 'is empty' do
        expect(json[:service_desk_address]).to be_nil
      end
    end
  end

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

  describe '.ci/cd settings' do
    context 'when the user is not an admin' do
      before do
        project.add_reporter(current_user)
      end

      it 'does not return ci settings' do
        expect(json[:ci_default_git_depth]).to be_nil
      end
    end

    context 'when the user has admin privileges' do
      before do
        project.add_maintainer(current_user)
      end

      it 'returns ci settings' do
        expect(json[:ci_default_git_depth]).to be_present
      end
    end
  end
end
