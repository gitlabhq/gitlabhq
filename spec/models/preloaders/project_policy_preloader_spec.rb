# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::ProjectPolicyPreloader do
  let_it_be(:user) { create(:user) }
  let_it_be(:root_parent) { create(:group, :private, name: 'root-1', path: 'root-1') }
  let_it_be(:guest_project) { create(:project, name: 'public guest', path: 'public-guest', guests: user) }
  let_it_be(:private_maintainer_project) do
    create(:project, :private, name: 'b private maintainer', path: 'b-private-maintainer', namespace: root_parent,
      maintainers: user)
  end

  let_it_be(:private_developer_project) do
    create(:project, :private, name: 'c public developer', path: 'c-public-developer', developers: user)
  end

  let_it_be(:public_maintainer_project) do
    create(:project, :private, name: 'a public maintainer', path: 'a-public-maintainer', maintainers: user)
  end

  let(:base_projects) do
    Project.where(id: [guest_project, private_maintainer_project, private_developer_project, public_maintainer_project])
  end

  it 'avoids N+1 queries when authorizing a list of projects', :request_store do
    preload_projects_for_policy(user)
    control = ActiveRecord::QueryRecorder.new { authorize_all_projects(user) }

    new_project1 = create(:project, :private, maintainers: user)
    new_project2 = create(:project, :private, namespace: root_parent, maintainers: user)

    another_root = create(:group, :private, name: 'root-3', path: 'root-3')
    new_project3 = create(:project, :private, namespace: another_root, maintainers: user)

    pristine_projects = Project.where(id: base_projects + [new_project1, new_project2, new_project3])

    preload_projects_for_policy(user, pristine_projects)
    expect { authorize_all_projects(user, pristine_projects) }.not_to exceed_query_limit(control)
  end

  def authorize_all_projects(current_user, project_list = base_projects)
    project_list.each { |project| current_user.can?(:read_project, project) }
  end

  def preload_projects_for_policy(current_user, project_list = base_projects)
    described_class.new(project_list, current_user).execute
  end
end
