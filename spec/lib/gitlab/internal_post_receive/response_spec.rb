# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::InternalPostReceive::Response do
  subject { described_class.new }

  describe '#add_merge_request_urls' do
    context 'when there are urls_data' do
      it 'adds a message for each merge request URL' do
        urls_data = [
          { new_merge_request: false, branch_name: 'foo', url: 'http://example.com/foo/bar/-/merge_requests/1' },
          { new_merge_request: true, branch_name: 'bar', url: 'http://example.com/foo/bar/-/merge_requests/new?merge_request%5Bsource_branch%5D=bar' }
        ]

        subject.add_merge_request_urls(urls_data)

        expected = [a_kind_of(described_class::Message), a_kind_of(described_class::Message)]
        expect(subject.messages).to match(expected)
      end
    end
  end

  describe '#add_merge_request_url' do
    context 'when :new_merge_request is false' do
      it 'adds a basic message to view the existing merge request' do
        url_data = { new_merge_request: false, branch_name: 'foo', url: 'http://example.com/foo/bar/-/merge_requests/1' }

        subject.add_merge_request_url(url_data)

        message = <<~MESSAGE.strip
          View merge request for foo:
            http://example.com/foo/bar/-/merge_requests/1
        MESSAGE

        expect(subject.messages.first.message).to eq(message)
        expect(subject.messages.first.type).to eq(:basic)
      end
    end

    context 'when :new_merge_request is true' do
      it 'adds a basic message to create a new merge request' do
        url_data = { new_merge_request: true, branch_name: 'bar', url: 'http://example.com/foo/bar/-/merge_requests/new?merge_request%5Bsource_branch%5D=bar' }

        subject.add_merge_request_url(url_data)

        message = <<~MESSAGE.strip
          To create a merge request for bar, visit:
            http://example.com/foo/bar/-/merge_requests/new?merge_request%5Bsource_branch%5D=bar
        MESSAGE

        expect(subject.messages.first.message).to eq(message)
        expect(subject.messages.first.type).to eq(:basic)
      end
    end
  end

  describe '#add_basic_message' do
    context 'when text is present' do
      it 'adds a basic message' do
        subject.add_basic_message('hello')

        expect(subject.messages.first.message).to eq('hello')
        expect(subject.messages.first.type).to eq(:basic)
      end
    end

    context 'when text is blank' do
      it 'does not add a message' do
        subject.add_basic_message(' ')

        expect(subject.messages).to be_blank
      end
    end
  end

  describe '#add_alert_message' do
    context 'when text is present' do
      it 'adds an alert message' do
        subject.add_alert_message('hello')

        expect(subject.messages.first.message).to eq('hello')
        expect(subject.messages.first.type).to eq(:alert)
      end
    end

    context 'when text is blank' do
      it 'does not add a message' do
        subject.add_alert_message(' ')

        expect(subject.messages).to be_blank
      end
    end
  end

  describe '#reference_counter_decreased' do
    context 'initially' do
      it 'reference_counter_decreased is set to false' do
        expect(subject.reference_counter_decreased).to eq(false)
      end
    end
  end

  describe '#reference_counter_decreased=' do
    context 'when the argument is truthy' do
      it 'reference_counter_decreased is truthy' do
        subject.reference_counter_decreased = true

        expect(subject.reference_counter_decreased).to be_truthy
      end
    end

    context 'when the argument is falsey' do
      it 'reference_counter_decreased is falsey' do
        subject.reference_counter_decreased = false

        expect(subject.reference_counter_decreased).to be_falsey
      end
    end
  end
end
