# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::QueryLogs::Tags, feature_category: :database do
  describe '.line' do
    subject(:line) { described_class.line({}) }

    it 'returns a path relative to the application root, as the marginalia :line component did' do
      expect(line).to start_with('/')
      expect(line).not_to start_with(Rails.root.to_s)
    end

    it 'returns the file, line and method of the frame' do
      expect(line).to match(%r{\A/.+\.rb:\d+:in .+\z})
    end

    it 'skips frames belonging to the query log tags themselves' do
      expect(line).not_to include('lib/gitlab/query_logs/tags.rb')
    end
  end

  describe '.endpoint_id' do
    it 'returns the caller id from the Labkit context' do
      Labkit::Context.with_context(caller_id: 'Foo#bar') do
        expect(described_class.endpoint_id({})).to eq('Foo#bar')
      end
    end
  end

  describe '.correlation_id' do
    it 'returns the current correlation id when there is no job' do
      Labkit::Correlation::CorrelationId.use_id('cid1') do
        expect(described_class.correlation_id({})).to eq('cid1')
      end
    end

    it 'prefers the correlation id of the job' do
      context = { job: { 'correlation_id' => 'job-cid' } }

      Labkit::Correlation::CorrelationId.use_id('cid1') do
        expect(described_class.correlation_id(context)).to eq('job-cid')
      end
    end
  end

  describe '.jid' do
    it 'returns nothing when there is no job' do
      expect(described_class.jid({})).to be_nil
    end

    it 'returns the jid of a Sidekiq job' do
      expect(described_class.jid({ job: { 'jid' => 'abc123' } })).to eq('abc123')
    end

    it 'returns the job id of an ActionMailer delivery job' do
      job = ActionMailer::MailDeliveryJob.new('Mailer', 'method', 'deliver_now')

      expect(described_class.jid({ job: job })).to eq(job.job_id)
    end
  end
end
