# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/projects/_project_card.html.haml', feature_category: :shared do
  let(:project) { build(:project) }

  before do
    allow(view)
      .to receive(:current_application_settings)
      .and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:can?).and_return(true)
  end

  it 'renders as a card component' do
    render 'shared/projects/project_card', use_creator_avatar: true, project: project

    expect(rendered).to have_selector('.gl-card')
  end

  it 'renders creator avatar if project has a creator' do
    render 'shared/projects/project_card', use_creator_avatar: true, project: project

    expect(rendered).to have_selector('img.gl-avatar')
  end

  it 'renders a generic avatar if project does not have a creator' do
    project.creator = nil

    render 'shared/projects/project_card', use_creator_avatar: true, project: project

    expect(rendered).to have_selector('.gl-avatar-identicon')
  end
end
