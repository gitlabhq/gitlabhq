# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/projects/_dormant_project_deletion_alert', feature_category: :groups_and_projects do
  let_it_be(:project) { build_stubbed(:project) }

  let(:text) do
    format(
      _('Due to inactivity, this project is scheduled to be deleted on %{deletion_date}. Why is this scheduled?'),
      deletion_date: '2022-04-01'
    )
  end

  shared_examples 'does not render' do
    before do
      render
    end

    it { expect(rendered).not_to have_content(text) }
  end

  before do
    allow(view).to receive(:dormant_project_deletion_date).with(project).and_return('2022-04-01')
  end

  context 'without a project' do
    before do
      assign(:project, nil)
    end

    it_behaves_like 'does not render'
  end

  context 'with a project' do
    before do
      assign(:project, project)
      allow(view).to receive(:show_dormant_project_deletion_banner?).and_return(dormant)
    end

    context 'when the project is active' do
      let(:dormant) { false }

      it_behaves_like 'does not render'
    end

    context 'when the project is dormant' do
      let(:dormant) { true }

      before do
        render
      end

      it 'does render the alert' do
        expect(rendered).to have_content(text)
      end
    end
  end
end
