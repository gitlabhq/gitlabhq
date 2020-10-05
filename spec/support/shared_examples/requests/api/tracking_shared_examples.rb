# frozen_string_literal: true

RSpec.shared_examples 'a gitlab tracking event' do |category, action|
  it "creates a gitlab tracking event #{action}" do
    expect(Gitlab::Tracking).to receive(:event).with(category, action, {})

    subject
  end
end
