# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/projects/_project.html.haml' do
  let_it_be(:project) { create(:project) }

  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:can?) { true }
  end

  it 'renders creator avatar if project has a creator', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/472013' do
    render 'shared/projects/project', use_creator_avatar: true, project: project

    expect(rendered).to have_selector('img.gl-avatar')
  end

  it 'renders a generic avatar if project does not have a creator' do
    project.creator = nil

    render 'shared/projects/project', use_creator_avatar: true, project: project

    expect(rendered).to have_selector('.gl-avatar-identicon')
  end
end
