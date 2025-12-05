# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'kaminari/gitlab/_without_count', feature_category: :groups_and_projects do
  let(:locals) { { event_tracking: 'foo_bar', previous_path: '/prev', next_path: '/next' } }

  before do
    render locals: locals
  end

  context 'when previous_path and next_path are set' do
    it 'renders next link' do
      expect(rendered).to have_selector(
        # rubocop:disable Layout/LineLength -- A reason is required but it's quite obvious why this is being disabled.
        'a[href="/next"][data-event-tracking="foo_bar"][data-event-label="next"][data-testid="kaminari-pagination-next"]'
        # rubocop:enable Layout/LineLength
      )
    end

    it 'renders prev link' do
      expect(rendered).to have_selector(
        # rubocop:disable Layout/LineLength -- A reason is required but it's quite obvious why this is being disabled.
        'a[href="/prev"][data-event-tracking="foo_bar"][data-event-label="prev"][data-testid="kaminari-pagination-prev"]'
        # rubocop:enable Layout/LineLength
      )
    end
  end

  context 'when previous_path is not set' do
    let(:locals) { { event_tracking: 'foo_bar', previous_path: nil, next_path: '/next' } }

    it 'renders prev as disabled' do
      expect(rendered).to have_selector(
        'li[aria-disabled="true"] [data-testid="kaminari-pagination-prev"]'
      )
    end
  end

  context 'when next path is not set' do
    let(:locals) { { event_tracking: 'foo_bar', previous_path: '/prev', next_path: nil } }

    it 'renders next as disabled' do
      expect(rendered).to have_selector(
        'li[aria-disabled="true"] [data-testid="kaminari-pagination-next"]'
      )
    end
  end
end
