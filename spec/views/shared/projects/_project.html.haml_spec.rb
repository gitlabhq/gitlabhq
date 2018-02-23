require 'spec_helper'

describe 'shared/projects/_project.html.haml' do
  let(:project) { create(:project) }

  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:can?) { true }
  end

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
