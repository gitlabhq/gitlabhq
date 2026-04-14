# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::StartAndDueDate, feature_category: :team_planning do
  let(:start_date) { Date.new(2025, 1, 2) }
  let(:due_date) { Date.new(2025, 1, 16) }
  let(:widget) do
    attrs = {
      start_date: start_date,
      due_date: due_date,
      can_rollup?: false
    }

    if Gitlab.ee?
      attrs.merge!(
        fixed?: true,
        start_date_sourcing_work_item: nil,
        start_date_sourcing_milestone: nil,
        due_date_sourcing_work_item: nil,
        due_date_sourcing_milestone: nil
      )
    end

    instance_double(WorkItems::Widgets::StartAndDueDate, **attrs)
  end

  subject(:representation) { described_class.new(widget).as_json }

  it 'exposes the start and due dates from the widget' do
    expect(representation).to include(start_date: start_date, due_date: due_date)
  end

  it_behaves_like 'work item widget entity parity',
    described_class,
    Types::WorkItems::Widgets::StartAndDueDateType
end
