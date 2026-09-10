# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'

load File.expand_path('../../../spec/support/matchers/have_testid.rb', __dir__)

RSpec.describe 'have_testid matcher', feature_category: :tooling do
  it 'matches when the testid is present' do
    node = Capybara.string('<div data-testid="foo">hello</div>')

    expect(node).to have_testid('foo')
  end

  it 'matches when the testid is absent' do
    node = Capybara.string('<div data-testid="other">hello</div>')

    # match_when_negated defines does_not_match? on the matcher
    expect(have_testid('missing')).to respond_to(:does_not_match?)
    expect(node).not_to have_testid('missing')
  end

  describe 'failure messages' do
    let(:node) { instance_double(Capybara::Node::Element) }

    before do
      allow(node).to receive_messages(has_selector?: false, has_no_selector?: false)
    end

    context 'when called with no options' do
      it 'does not mention text' do
        matcher = have_testid('my-testid')
        matcher.matches?(node)

        expect(matcher.failure_message).to eq("expected to find element with data-testid='my-testid'")
      end

      it 'does not mention text when negated' do
        matcher = have_testid('my-testid')
        matcher.does_not_match?(node)

        expect(matcher.failure_message_when_negated).to eq("expected not to find element with data-testid='my-testid'")
      end
    end

    context 'when called with text: option' do
      it 'includes the expected text' do
        matcher = have_testid('my-testid', text: 'hello')
        matcher.matches?(node)

        expect(matcher.failure_message)
          .to eq("expected to find element with data-testid='my-testid' containing text 'hello'")
      end

      it 'includes the expected text when negated' do
        matcher = have_testid('my-testid', text: 'hello')
        matcher.does_not_match?(node)

        expect(matcher.failure_message_when_negated)
          .to eq("expected not to find element with data-testid='my-testid' containing text 'hello'")
      end
    end
  end
end
