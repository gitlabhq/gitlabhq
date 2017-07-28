require 'spec_helper'

describe 'projects/registry/repositories/index' do
  let(:group) { create(:group, path: 'group') }
  let(:project) { create(:empty_project, group: group, path: 'test') }

  let(:repository) do
    create(:container_repository, project: project, name: 'image')
  end

  before do
    stub_container_registry_config(enabled: true,
                                   host_port: 'registry.gitlab',
                                   api_url: 'http://registry.gitlab')

    stub_container_registry_tags(repository: :any, tags: [:latest])

    assign(:project, project)
    assign(:images, [repository])

    allow(view).to receive(:can?).and_return(true)
  end

  it 'contains container repository path' do
    render

    expect(rendered).to have_content 'group/test/image'
  end

  it 'contains attribute for copying tag location into clipboard' do
    render

    expect(rendered).to have_css 'button[data-clipboard-text="docker pull ' \
                                 'registry.gitlab/group/test/image:latest"]'
  end
end
