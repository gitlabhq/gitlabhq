# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_context 'GroupProjectsFinder context' do
  let(:group) { create(:group) }
  let(:subgroup) { create(:group, parent: group) }
  let(:current_user) { create(:user) }
  let(:options) { {} }

  let(:finder) { described_class.new(group: group, current_user: current_user, options: options) }

  let!(:public_project) { create(:project, :public, group: group, path: '1') }
  let!(:private_project) { create(:project, :private, group: group, path: '2') }
  let!(:shared_project_1) { create(:project, :public, path: '3') }
  let!(:shared_project_2) { create(:project, :private, path: '4') }
  let!(:shared_project_3) { create(:project, :internal, path: '5') }
  let!(:subgroup_project) { create(:project, :public, path: '6', group: subgroup) }
  let!(:subgroup_private_project) { create(:project, :private, path: '7', group: subgroup) }

  before do
    shared_project_1.project_group_links.create(group_access: Gitlab::Access::MAINTAINER, group: group)
    shared_project_2.project_group_links.create(group_access: Gitlab::Access::MAINTAINER, group: group)
    shared_project_3.project_group_links.create(group_access: Gitlab::Access::MAINTAINER, group: group)
  end
end
