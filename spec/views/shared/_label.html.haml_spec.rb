# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_label.html.haml', feature_category: :team_planning do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:current_user) { build_stubbed(:user) }

  before do
    assign(:project, project)
    allow(view).to receive(:can?).and_return(true)

    render partial: 'shared/label', locals: { label: label, current_user: current_user }
  end

  context 'with active label' do
    let(:label) { build_stubbed(:label, project: project) }

    it 'allows toggling priority' do
      expect(rendered).to have_css('.js-toggle-priority')
    end
  end

  context 'with archived label' do
    let(:label) { build_stubbed(:label, :archived, project: project) }

    it 'does not allow toggling priority' do
      expect(rendered).not_to have_css('.js-toggle-priority')
    end
  end
end
