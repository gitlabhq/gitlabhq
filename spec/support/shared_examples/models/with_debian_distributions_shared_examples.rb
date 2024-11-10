# frozen_string_literal: true

RSpec.shared_examples 'model with Debian distributions' do
  let(:container_type) { subject.class.name.downcase }
  let!(:distributions) { create_list("debian_#{container_type}_distribution", 2, :with_file, container: subject) }
  let!(:components) { create_list("debian_#{container_type}_component", 5, distribution: distributions[0]) }
  let!(:component_files) { create_list("debian_#{container_type}_component_file", 3, component: components[0]) }

  it 'removes distribution files on removal' do
    distribution_file_paths = distributions.flat_map do |distribution|
      [distribution.file.path] +
        distribution.component_files.flat_map do |component_file|
          component_file.file.path
        end
    end

    expect { subject.destroy! }
      .to change {
        distribution_file_paths.select do |path|
          File.exist? path
        end.length
      }.from(distribution_file_paths.length).to(0)
  end
end
