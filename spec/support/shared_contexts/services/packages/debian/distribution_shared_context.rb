# frozen_string_literal: true

RSpec.shared_context 'with published Debian package' do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:project_distribution) { create(:debian_project_distribution, container: project, codename: 'unstable', valid_time_duration_seconds: 48.hours.to_i) }
  let_it_be(:package) { create(:debian_package, project: project, published_in: project_distribution) }
end

RSpec.shared_context 'with Debian distribution' do |container_type|
  let_it_be(:container_type) { container_type }

  if container_type == :project
    let_it_be(:container) { project }
    let_it_be(:distribution, reload: true) { project_distribution }
  else
    let_it_be(:container) { group }
    let_it_be(:distribution, reload: true) { create(:debian_group_distribution, container: group, codename: 'unstable', valid_time_duration_seconds: 48.hours.to_i) }
  end
end
