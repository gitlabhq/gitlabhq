require 'spec_helper'

describe Gitlab::Metrics::Subscribers::ActionView do
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }

  let(:subscriber) { described_class.new }

  let(:event) do
    root = Rails.root.to_s

    double(:event, duration: 2.1,
                   payload:  { identifier: "#{root}/app/views/x.html.haml" })
  end

  before do
    allow(subscriber).to receive(:current_transaction).and_return(transaction)
  end

  describe '#render_template' do
    it 'tracks rendering of a template' do
      values = { duration: 2.1 }
      tags   = { view: 'app/views/x.html.haml' }

      expect(transaction).to receive(:increment)
        .with(:view_duration, 2.1)

      expect(transaction).to receive(:add_metric)
        .with(described_class::SERIES, values, tags)

      subscriber.render_template(event)
    end

    it 'observes view rendering time' do
      expect(described_class.gitlab_view_rendering_duration_seconds)
        .to receive(:observe)
              .with({ view: 'app/views/x.html.haml' }, 2.1)

      subscriber.render_template(event)
    end
  end
end
