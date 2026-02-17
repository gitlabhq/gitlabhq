# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::Description, feature_category: :team_planning do
  let(:user) { build(:user) }
  let(:last_edited_at) { Time.zone.parse('2024-12-01 10:30:00 UTC') }
  let(:task_completion_status) { { count: 3, completed_count: 1 } }

  let(:work_item) do
    build(
      :work_item,
      description: 'Refine keyboard shortcut mappings',
      description_html: '<p>Refine keyboard shortcut mappings</p>',
      last_edited_at: last_edited_at,
      last_edited_by: user
    ).tap do |item|
      allow(item).to receive(:task_completion_status).and_return(task_completion_status)
    end
  end

  let(:widget) { WorkItems::Widgets::Description.new(work_item) }

  subject(:representation) do
    described_class.new(widget).as_json
  end

  it 'exposes the description feature payload' do
    aggregate_failures do
      expect(representation).to include(
        description: 'Refine keyboard shortcut mappings',
        description_html: '<p>Refine keyboard shortcut mappings</p>'
      )

      expect(representation).to include(edited: true)
      expect(representation[:last_edited_at]).to eq(last_edited_at)

      expected_editor = API::Entities::UserBasic
        .new(user)
        .as_json

      expect(representation[:last_edited_by]).to eq(expected_editor)
      expect(representation[:task_completion_status]).to eq(task_completion_status)
    end
  end
end
