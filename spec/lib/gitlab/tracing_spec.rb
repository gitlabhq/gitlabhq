# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

describe Gitlab::Tracing do
  using RSpec::Parameterized::TableSyntax

  describe '.enabled?' do
    where(:connection_string, :enabled_state) do
      nil                     | false
      ""                      | false
      "opentracing://jaeger"  | true
    end

    with_them do
      it 'returns the correct state for .enabled?' do
        expect(described_class).to receive(:connection_string).and_return(connection_string)

        expect(described_class.enabled?).to eq(enabled_state)
      end
    end
  end

  describe '.tracing_url_enabled?' do
    where(:enabled?, :tracing_url_template, :tracing_url_enabled_state) do
      false | nil                | false
      false | ""                 | false
      false | "http://localhost" | false
      true  | nil                | false
      true  | ""                 | false
      true  | "http://localhost" | true
    end

    with_them do
      it 'returns the correct state for .tracing_url_enabled?' do
        expect(described_class).to receive(:enabled?).and_return(enabled?)
        allow(described_class).to receive(:tracing_url_template).and_return(tracing_url_template)

        expect(described_class.tracing_url_enabled?).to eq(tracing_url_enabled_state)
      end
    end
  end

  describe '.tracing_url' do
    where(:tracing_url_enabled?, :tracing_url_template, :correlation_id, :process_name, :tracing_url) do
      false | "https://localhost"                                              | "123" | "web" | nil
      true  | "https://localhost"                                              | "123" | "web" | "https://localhost"
      true  | "https://localhost?service={{ service }}"                        | "123" | "web" | "https://localhost?service=web"
      true  | "https://localhost?c={{ correlation_id }}"                       | "123" | "web" | "https://localhost?c=123"
      true  | "https://localhost?c={{ correlation_id }}&s={{ service }}"       | "123" | "web" | "https://localhost?c=123&s=web"
      true  | "https://localhost?c={{ correlation_id }}"                       | nil   | "web" | "https://localhost?c="
      true  | "https://localhost?c={{ correlation_id }}&s=%22{{ service }}%22" | "123" | "web" | "https://localhost?c=123&s=%22web%22"
      true  | "https://localhost?c={{correlation_id}}&s={{service}}"           | "123" | "web" | "https://localhost?c=123&s=web"
      true  | "https://localhost?c={{correlation_id }}&s={{ service}}"         | "123" | "web" | "https://localhost?c=123&s=web"
    end

    with_them do
      it 'returns the correct state for .tracing_url' do
        expect(described_class).to receive(:tracing_url_enabled?).and_return(tracing_url_enabled?)
        allow(described_class).to receive(:tracing_url_template).and_return(tracing_url_template)
        allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return(correlation_id)
        allow(Gitlab).to receive(:process_name).and_return(process_name)

        expect(described_class.tracing_url).to eq(tracing_url)
      end
    end
  end
end
