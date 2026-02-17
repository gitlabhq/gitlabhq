# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::StartAndDueDate, feature_category: :team_planning do
  let(:start_date) { Date.new(2025, 1, 2) }
  let(:due_date) { Date.new(2025, 1, 16) }
  let(:widget) do
    instance_double(
      WorkItems::Widgets::StartAndDueDate,
      start_date: start_date,
      due_date: due_date
    )
  end

  subject(:representation) do
    described_class.new(widget).as_json
  end

  it 'exposes the start and due dates from the widget' do
    expect(representation).to include(start_date: start_date, due_date: due_date)
  end
end
