# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

describe Gitlab::Tracing::Rails::ActionViewSubscriber do
  using RSpec::Parameterized::TableSyntax

  shared_examples 'an actionview notification' do
    it 'notifies the tracer when the hash contains null values' do
      expect(subject).to receive(:postnotify_span).with(notification_name, start, finish, tags: expected_tags, exception: exception)

      subject.public_send(notify_method, start, finish, payload)
    end

    it 'notifies the tracer when the payload is missing values' do
      expect(subject).to receive(:postnotify_span).with(notification_name, start, finish, tags: expected_tags, exception: exception)

      subject.public_send(notify_method, start, finish, payload.compact)
    end

    it 'does not throw exceptions when with the default tracer' do
      expect { subject.public_send(notify_method, start, finish, payload) }.not_to raise_error
    end
  end

  describe '.instrument' do
    it 'is unsubscribeable' do
      unsubscribe = described_class.instrument

      expect(unsubscribe).not_to be_nil
      expect { unsubscribe.call }.not_to raise_error
    end
  end

  describe '#notify_render_template' do
    subject { described_class.new }
    let(:start) { Time.now }
    let(:finish) { Time.now }
    let(:notification_name) { 'render_template' }
    let(:notify_method) { :notify_render_template }

    where(:identifier, :layout, :exception) do
      nil         | nil           | nil
      ""          | nil           | nil
      "show.haml" | nil           | nil
      nil         | ""            | nil
      nil         | "layout.haml" | nil
      nil         | nil           | StandardError.new
    end

    with_them do
      let(:payload) do
        {
          exception: exception,
          identifier: identifier,
          layout: layout
        }
      end

      let(:expected_tags) do
        {
          'component' =>       'ActionView',
          'template.id' =>     identifier,
          'template.layout' => layout
        }
      end

      it_behaves_like 'an actionview notification'
    end
  end

  describe '#notify_render_collection' do
    subject { described_class.new }
    let(:start) { Time.now }
    let(:finish) { Time.now }
    let(:notification_name) { 'render_collection' }
    let(:notify_method) { :notify_render_collection }

    where(
      :identifier, :count, :expected_count, :cache_hits, :expected_cache_hits, :exception) do
      nil         | nil           | 0 | nil | 0 | nil
      ""          | nil           | 0 | nil | 0 | nil
      "show.haml" | nil           | 0 | nil | 0 | nil
      nil         | 0             | 0 | nil | 0 | nil
      nil         | 1             | 1 | nil | 0 | nil
      nil         | nil           | 0 | 0   | 0 | nil
      nil         | nil           | 0 | 1   | 1 | nil
      nil         | nil           | 0 | nil | 0 | StandardError.new
    end

    with_them do
      let(:payload) do
        {
          exception: exception,
          identifier: identifier,
          count: count,
          cache_hits: cache_hits
        }
      end

      let(:expected_tags) do
        {
          'component' =>            'ActionView',
          'template.id' =>          identifier,
          'template.count' =>       expected_count,
          'template.cache.hits' =>  expected_cache_hits
        }
      end

      it_behaves_like 'an actionview notification'
    end
  end

  describe '#notify_render_partial' do
    subject { described_class.new }
    let(:start) { Time.now }
    let(:finish) { Time.now }
    let(:notification_name) { 'render_partial' }
    let(:notify_method) { :notify_render_partial }

    where(:identifier, :exception) do
      nil         | nil
      ""          | nil
      "show.haml" | nil
      nil         | StandardError.new
    end

    with_them do
      let(:payload) do
        {
          exception: exception,
          identifier: identifier
        }
      end

      let(:expected_tags) do
        {
          'component' =>            'ActionView',
          'template.id' =>          identifier
        }
      end

      it_behaves_like 'an actionview notification'
    end
  end
end
