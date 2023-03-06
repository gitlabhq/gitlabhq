# frozen_string_literal: true

RSpec.shared_examples 'updates merge widget in real-time' do
  specify do
    wait_for_requests

    # Simulate a real-time update of merge widget
    trigger_action

    expect(find('.mr-state-widget')).to have_content(widget_text)
  end
end
