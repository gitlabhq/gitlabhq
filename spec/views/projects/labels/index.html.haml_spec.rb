# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/labels/index.html.haml', :aggregate_failures, feature_category: :team_planning do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- View spec requires database records for queries
  let_it_be(:project) { create(:project) }
  let_it_be(:label) { create(:label, project: project, title: 'Regular Label') }
  let_it_be(:archived_label) { create(:label, :archived, project: project, title: 'Archived Label') }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  before do
    assign(:project, project)
    assign(:available_labels, Label.where(project: project))
  end

  context 'with prioritized labels' do
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- View spec requires database records for queries
    let_it_be(:prioritized_label) { create(:label, project: project, title: 'Priority Label', priority: 1) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    context 'when viewing active labels' do
      before do
        assign(:prioritized_labels, Label.where(project: project).prioritized(project))
        assign(:labels, Label.where(project: project).unprioritized(project).page(1))

        render
      end

      it 'shows the prioritized labels section' do
        expect(rendered).to have_css('.prioritized-labels')
        expect(rendered).not_to have_css('.prioritized-labels.gl-hidden')
        expect(rendered).to have_text(prioritized_label.title)
      end

      it 'shows active label' do
        expect(rendered).to have_text(label.title)
      end
    end

    context 'when viewing archived tab' do
      before do
        assign(:prioritized_labels, Label.where(project: project).prioritized(project))
        assign(:labels, Label.where(project: project, archived: true).page(1))

        allow(view).to receive(:params).and_return({ archived: 'true' })
      end

      context 'when labels_archive feature flag is enabled' do
        before do
          render
        end

        it 'hides the prioritized labels section' do
          expect(rendered).to have_css('.prioritized-labels.gl-hidden')
        end

        it 'shows archived labels' do
          expect(rendered).to have_text(archived_label.title)
        end

        it 'does not show active label' do
          expect(rendered).not_to have_text(label.title)
        end
      end

      context 'when labels_archive feature flag is disabled' do
        before do
          stub_feature_flags(labels_archive: false)
          render
        end

        it 'still shows the prioritized labels section when feature flag is disabled' do
          expect(rendered).to have_css('.prioritized-labels')
          expect(rendered).not_to have_css('.prioritized-labels.gl-hidden')
          expect(rendered).to have_text(prioritized_label.title)
        end
      end
    end
  end

  context 'when there are no prioritized labels but not on archived tab' do
    before do
      assign(:prioritized_labels, Label.none)
      assign(:labels, Label.where(project: project, archived: false).page(1))

      render
    end

    it 'still shows the prioritized labels section (even though empty)' do
      expect(rendered).to have_css('.prioritized-labels')
      expect(rendered).not_to have_css('.prioritized-labels.gl-hidden')
    end

    it 'shows empty state for prioritized labels' do
      expect(rendered).to have_css('#js-priority-labels-empty-state')
    end
  end
end
