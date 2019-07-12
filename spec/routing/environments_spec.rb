require 'spec_helper'

describe 'environments routing' do
  let(:project) { create(:project) }

  let(:environment) do
    create(:environment, project: project,
                         name: 'staging-1.0/review')
  end

  let(:environments_route) do
    "#{project.full_path}/environments/"
  end

  describe 'routing environment folders' do
    context 'when using JSON format' do
      it 'correctly matches environment name and JSON format' do
        expect(get_folder('staging-1.0.json'))
          .to route_to(*folder_action(id: 'staging-1.0', format: 'json'))
      end
    end

    context 'when using HTML format' do
      it 'correctly matches environment name and HTML format' do
        expect(get_folder('staging-1.0.html'))
          .to route_to(*folder_action(id: 'staging-1.0', format: 'html'))
      end
    end

    context 'when using implicit format' do
      it 'correctly matches environment name' do
        expect(get_folder('staging-1.0'))
          .to route_to(*folder_action(id: 'staging-1.0'))
      end
    end
  end

  def get_folder(folder)
    get("#{project.full_path}/environments/folders/#{folder}")
  end

  def folder_action(**opts)
    options = { namespace_id: project.namespace.path,
                project_id: project.path }

    ['projects/environments#folder', options.merge(opts)]
  end
end
