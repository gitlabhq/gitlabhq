# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/projects/_removed.html.haml', feature_category: :groups_and_projects do
  let(:project) { build_stubbed(:project) }

  before do
    allow(view).to receive(:permanent_deletion_date_formatted).and_return('2026-05-22')
  end

  context 'when project is not scheduled for deletion' do
    before do
      allow(project).to receive(:self_deletion_scheduled?).and_return(false)
    end

    it 'renders nothing' do
      render 'shared/projects/removed', project: project

      expect(rendered).to be_empty
    end
  end

  context 'when project is scheduled for deletion via the legacy marked_for_deletion_at column' do
    let(:deletion_date) { Date.new(2026, 4, 22) }

    before do
      allow(project).to receive_messages(
        self_deletion_scheduled?: true,
        self_deletion_scheduled_deletion_created_on: deletion_date
      )
    end

    it 'renders the deletion date using self_deletion_scheduled_deletion_created_on' do
      render 'shared/projects/removed', project: project

      expect(rendered).to include(deletion_date.strftime(Date::DATE_FORMATS[:medium]))
    end
  end

  context 'when project is scheduled for deletion via state-metadata (marked_for_deletion_at is nil)' do
    let(:deletion_date) { Date.new(2026, 4, 15) }

    before do
      allow(project).to receive_messages(
        self_deletion_scheduled?: true,
        marked_for_deletion_at: nil,
        self_deletion_scheduled_deletion_created_on: deletion_date
      )
    end

    it 'renders the deletion date without raising a NoMethodError on nil' do
      render 'shared/projects/removed', project: project

      expect(rendered).to include(deletion_date.strftime(Date::DATE_FORMATS[:medium]))
    end
  end

  context 'when project is scheduled for deletion but self_deletion_scheduled_deletion_created_on is nil' do
    before do
      allow(project).to receive_messages(
        self_deletion_scheduled?: true,
        self_deletion_scheduled_deletion_created_on: nil
      )
    end

    it 'renders without raising a NoMethodError' do
      expect { render 'shared/projects/removed', project: project }.not_to raise_error
    end

    it 'does not render the marked for deletion date line' do
      render 'shared/projects/removed', project: project

      expect(rendered).not_to include('Marked For Deletion At')
    end
  end
end
