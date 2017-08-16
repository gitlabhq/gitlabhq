require 'spec_helper'

describe 'shared/projects/_project.html.haml' do
  let(:project) { create(:project) }

  it 'should render creator avatar if project has a creator' do
    render 'shared/projects/project', use_creator_avatar: true, project: project

    expect(rendered).to have_selector('img.avatar')
  end

  it 'should render a generic avatar if project does not have a creator' do
    project.creator = nil

    render 'shared/projects/project', use_creator_avatar: true, project: project

    expect(rendered).to have_selector('.project-avatar')
  end
end
