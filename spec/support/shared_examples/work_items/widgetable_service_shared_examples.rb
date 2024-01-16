# frozen_string_literal: true

RSpec.shared_examples_for 'work item widgetable service' do
  it 'executes callbacks for expected widgets' do
    supported_widgets.each do |widget|
      expect_next_instance_of(widget[:klass]) do |widget_instance|
        if widget[:params].present?
          expect(widget_instance).to receive(widget[:callback]).with(params: widget[:params])
        else
          expect(widget_instance).to receive(widget[:callback])
        end
      end
    end

    service_execute
  end
end
