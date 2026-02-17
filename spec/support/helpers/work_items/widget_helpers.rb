# frozen_string_literal: true

module WorkItems
  module WidgetHelpers
    # Stubs one or more widgets for a single work item instance.
    # This mocks both get_widget and has_widget? methods to simulate disabled widgets.
    # When a widget is disabled, get_widget returns nil (not the widget object) and
    # has_widget? returns false. Unstubbed widgets will use the original behavior.
    #
    # Examples:
    #   stub_work_item_widget(work_item, notes: false)
    #   stub_work_item_widget(work_item, labels: false, assignees: false, milestone: false)
    #   stub_work_item_widget(work_item, notes: true)
    #
    # Note: The enabled: true case doesn't fully work yet - it tries to return
    # the original widget but may not be useful if the type doesn't have it.
    # This can be improved in future iterations.
    def stub_work_item_widget(work_item, **widgets)
      # Set up default behavior to call original for any widget not explicitly stubbed
      allow(work_item).to receive(:get_widget).and_call_original
      allow(work_item).to receive(:has_widget?).and_call_original

      widgets.each do |widget, enabled|
        if enabled
          allow(work_item).to receive(:get_widget).with(widget).and_call_original
        else
          allow(work_item).to receive(:get_widget).with(widget).and_return(nil)
        end

        allow(work_item).to receive(:has_widget?).with(widget).and_return(enabled)
      end
    end

    # Stubs one or more widgets for all work item instances via allow_any_instance_of.
    # This is useful for testing behavior when widgets are not available across all work items.
    # When a widget is disabled, get_widget returns nil (not the widget object) and
    # has_widget? returns false. Unstubbed widgets will use the original behavior.
    #
    # Note: We stub the get_widget method with the WorkItem model as that's where the method is
    # defined and the has_widget? with the Issue model, for the same reasons.
    #
    # Examples:
    #   stub_all_work_item_widgets(notes: false)
    #   stub_all_work_item_widgets(labels: false, assignees: false, milestone: false)
    #   stub_all_work_item_widgets(notes: true)
    def stub_all_work_item_widgets(**widgets)
      # rubocop:disable RSpec/AnyInstanceOf -- To simulate work item without certain widgets
      # Set up default behavior to call original for any widget not explicitly stubbed
      allow_any_instance_of(WorkItem).to receive(:get_widget).and_call_original
      allow_any_instance_of(Issue).to receive(:has_widget?).and_call_original

      widgets.each do |widget, enabled|
        if enabled
          allow_any_instance_of(WorkItem).to receive(:get_widget).with(widget).and_call_original
        else
          allow_any_instance_of(WorkItem).to receive(:get_widget).with(widget).and_return(nil)
        end

        allow_any_instance_of(Issue).to receive(:has_widget?).with(widget).and_return(enabled)
      end
      # rubocop:enable RSpec/AnyInstanceOf
    end
  end
end
