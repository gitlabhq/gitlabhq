# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Subscribers::ActionView do
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }

  let(:subscriber) { described_class.new }

  let(:event) do
    root = Rails.root.to_s

    double(:event, duration: 2.1,
      payload: { identifier: "#{root}/app/views/x.html.haml" })
  end

  before do
    allow(subscriber).to receive(:current_transaction).and_return(transaction)
  end

  describe '#render_template' do
    it 'tracks rendering of a template' do
      expect(transaction).to receive(:increment)
        .with(:gitlab_transaction_view_duration_total, 2.1)

      subscriber.render_template(event)
    end

    it 'observes view rendering time' do
      expect(transaction)
        .to receive(:observe)
        .with(:gitlab_view_rendering_duration_seconds, 2.1, { view: "app/views/x.html.haml" })

      subscriber.render_template(event)
    end
  end
end
