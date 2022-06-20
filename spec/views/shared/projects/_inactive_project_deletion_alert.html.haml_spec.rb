# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/projects/_inactive_project_deletion_alert' do
  let_it_be(:project) { create(:project) }

  let(:text) { 'Due to inactivity, this project is scheduled to be deleted on 2022-04-01. Why is this scheduled?' }

  shared_examples 'does not render' do
    before do
      render
    end

    it { expect(rendered).not_to have_content(text) }
  end

  before do
    allow(view).to receive(:inactive_project_deletion_date).with(project).and_return('2022-04-01')
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
      allow(view).to receive(:show_inactive_project_deletion_banner?).and_return(inactive)
    end

    context 'when the project is active' do
      let(:inactive) { false }

      it_behaves_like 'does not render'
    end

    context 'when the project is inactive' do
      let(:inactive) { true }

      before do
        render
      end

      it 'does render the alert' do
        expect(rendered).to have_content(text)
      end
    end
  end
end
