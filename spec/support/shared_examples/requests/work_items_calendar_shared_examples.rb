# frozen_string_literal: true

# Guards the calendar (.ics) endpoint against an N+1 on WorkItem#due_date, which
# reads through the dates_source association. Both the project and group calendars
# share WorkItemsCollections#work_items_for_calendar, so both must preload it.
#
# Consumers must define:
#   let(:calendar_path)          - the .ics request path
#   let(:create_dated_work_item) - a callable that creates a work item with a due date
RSpec.shared_examples 'calendar endpoint without dates_source N+1' do
  it 'preloads dates_source, avoiding an N+1 while still rendering every work item' do
    create_dated_work_item.call

    get calendar_path

    control = ActiveRecord::QueryRecorder.new { get calendar_path }

    create_dated_work_item.call
    extra = create_dated_work_item.call

    expect { get calendar_path }.not_to exceed_query_limit(control)
    expect(response.body).to include(extra.title)
  end
end
