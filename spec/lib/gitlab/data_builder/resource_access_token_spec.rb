# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::ResourceAccessToken, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user, :project_bot) }
  let(:event) { :expiring }
  let(:personal_access_token) { create(:personal_access_token, user: user) }
  let(:data) { described_class.build(personal_access_token, event, resource) }

  shared_examples 'includes standard data' do
    specify do
      expect(data[:object_attributes]).to eq(personal_access_token.hook_attrs)
      expect(data[:object_kind]).to eq('access_token')
    end
  end

  context 'when token belongs to a project' do
    let_it_be_with_reload(:resource) { create(:project) }
    let_it_be_with_reload(:project) { resource }

    before_all do
      resource.add_developer(user)
    end

    it_behaves_like 'includes standard data'
    it_behaves_like 'project hook data'

    it "contains project data" do
      expect(data).to have_key(:project)
      expect(data[:event_name]).to eq("expiring_access_token")
    end
  end

  context 'when token belongs to a group' do
    let_it_be_with_reload(:resource) { create(:group) }

    before_all do
      resource.add_developer(user)
    end

    it_behaves_like 'includes standard data'

    it "contains group data" do
      expect(data[:group]).to eq({
        group_name: resource.name,
        group_path: resource.path,
        group_id: resource.id,
        full_path: resource.full_path
      })
      expect(data[:event_name]).to eq("expiring_access_token")
    end
  end
end
