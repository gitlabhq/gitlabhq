require 'spec_helper'

describe 'group routing' do
  let!(:existing_group) { create(:group, parent: create(:group, path: 'gitlab-org'), path: 'infra') }

  describe 'GET #labels' do
    it 'routes to the correct controller' do
      expect(get('/groups/gitlab-org/infra/-/labels'))
        .to route_to(group_id: 'gitlab-org/infra',
                     controller: 'groups/labels',
                     action: 'index')
    end

    it_behaves_like 'redirecting a legacy path', '/groups/gitlab-org/infra/labels', '/groups/gitlab-org/infra/-/labels' do
      let(:resource) { create(:group, parent: existing_group, path: 'labels') }
    end
  end
end
