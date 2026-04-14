# frozen_string_literal: true

RSpec.shared_context 'with published Debian package' do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:project_distribution) { create(:debian_project_distribution, container: project, codename: 'unstable', valid_time_duration_seconds: 48.hours.to_i) }
  # Create a duplicate package file with the same filename (libsample0_1.2.3~alpha2_amd64.deb)
  # to test that only the most recent file (highest ID) is included in Packages index
  let_it_be(:duplicate_package) { create(:debian_package, project: project, published_in: project_distribution, without_package_files: true) }
  let_it_be(:duplicate_package_file) do
    create(:debian_package_file, :deb, package: duplicate_package, file_name: 'libsample0_1.2.3~alpha2_amd64.deb')
  end

  let_it_be(:package) { create(:debian_package, project: project, published_in: project_distribution, with_symbols_file: true) }
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
