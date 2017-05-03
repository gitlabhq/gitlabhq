require 'spec_helper'

describe ::API::Helpers::InternalHelpers do
  include ::API::Helpers::InternalHelpers

  describe '.clean_project_path' do
    project = 'namespace/project'
    namespaced = File.join('namespace2', project)

    {
      File.join(Dir.pwd, project)    => project,
      File.join(Dir.pwd, namespaced) => namespaced,
      project                        => project,
      namespaced                     => namespaced,
      project + '.git'               => project,
      namespaced + '.git'            => namespaced,
      "/" + project                  => project,
      "/" + namespaced               => namespaced,
    }.each do |project_path, expected|
      context project_path do
        # Relative and absolute storage paths, with and without trailing /
        ['.', './', Dir.pwd, Dir.pwd + '/'].each do |storage_path|
          context "storage path is #{storage_path}" do
            subject { clean_project_path(project_path, [storage_path]) }

            it { is_expected.to eq(expected) }
          end
        end
      end
    end
  end
end
