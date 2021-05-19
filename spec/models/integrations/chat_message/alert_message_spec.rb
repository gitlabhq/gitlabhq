# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::AlertMessage do
  subject { described_class.new(args) }

  let_it_be(:start_time) { Time.current }

  let(:alert) { create(:alert_management_alert, started_at: start_time) }

  let(:args) do
    {
      project_name: 'project_name',
      project_url: 'http://example.com'
    }.merge(Gitlab::DataBuilder::Alert.build(alert))
  end

  describe '#message' do
    it 'returns the correct message' do
      expect(subject.message).to eq("Alert firing in #{args[:project_name]}")
    end
  end

  describe '#attachments' do
    it 'returns an array of one' do
      expect(subject.attachments).to be_a(Array)
      expect(subject.attachments.size).to eq(1)
    end

    it 'contains the correct attributes' do
      attachments_item = subject.attachments.first
      expect(attachments_item).to have_key(:title)
      expect(attachments_item).to have_key(:title_link)
      expect(attachments_item).to have_key(:color)
      expect(attachments_item).to have_key(:fields)
    end

    it 'returns the correct color' do
      expect(subject.attachments.first[:color]).to eq("#C95823")
    end

    it 'returns the correct attachment fields' do
      attachments_item = subject.attachments.first
      fields = attachments_item[:fields].map { |h| h[:title] }

      expect(fields).to match_array(['Severity', 'Events', 'Status', 'Start time'])
    end

    it 'returns the correctly formatted time' do
      time_item = subject.attachments.first[:fields].detect { |h| h[:title] == 'Start time' }

      expected_time = start_time.strftime("%B #{start_time.day.ordinalize}, %Y %l:%M%p %Z")

      expect(time_item[:value]).to eq(expected_time)
    end
  end
end
