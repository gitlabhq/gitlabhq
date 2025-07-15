# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/projects/_actions.html.haml', feature_category: :groups_and_projects do
  let_it_be(:project) { build_stubbed(:project) }

  context 'when project is not scheduled for deletion' do
    before do
      allow(project).to receive(:self_deletion_scheduled?).and_return(false)
    end

    it 'does not render a Restore button' do
      render 'shared/projects/actions', project: project

      expect(rendered).not_to have_content('Restore')
    end
  end

  context 'when project is scheduled for deletion' do
    before do
      allow(project).to receive(:self_deletion_scheduled?).and_return(true)
    end

    it 'renders a Restore button' do
      render 'shared/projects/actions', project: project

      expect(rendered).to have_content('Restore')
    end
  end
end
