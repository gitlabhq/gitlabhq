# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Metrics::Subscribers::Ldap, :request_store, feature_category: :observability do
  let(:transaction) { Gitlab::Metrics::WebTransaction.new({}) }
  let(:subscriber) { described_class.new }

  let(:attributes) do
    [
      :altServer, :namingContexts, :supportedCapabilities, :supportedControl,
      :supportedExtension, :supportedFeatures, :supportedLdapVersion, :supportedSASLMechanisms
    ]
  end

  let(:event_1) do
    instance_double(
      ActiveSupport::Notifications::Event,
      name: "open.net_ldap",
      payload: {
        ignore_server_caps: true,
        base: "",
        scope: 0,
        attributes: attributes,
        result: nil
      },
      time: Time.current,
      duration: 0.321
    )
  end

  let(:event_2) do
    instance_double(
      ActiveSupport::Notifications::Event,
      name: "search.net_ldap",
      payload: {
        ignore_server_caps: true,
        base: "",
        scope: 0,
        attributes: attributes,
        result: nil
      },
      time: Time.current,
      duration: 0.12
    )
  end

  let(:event_3) do
    instance_double(
      ActiveSupport::Notifications::Event,
      name: "search.net_ldap",
      payload: {
        ignore_server_caps: true,
        base: "",
        scope: 0,
        attributes: attributes,
        result: nil
      },
      time: Time.current,
      duration: 5.3
    )
  end

  around do |example|
    freeze_time { example.run }
  end

  describe ".payload" do
    context "when SafeRequestStore is empty" do
      it "returns an empty array" do
        expect(described_class.payload).to eql(net_ldap_count: 0, net_ldap_duration_s: 0.0)
      end
    end

    context "when LDAP recorded some values" do
      before do
        Gitlab::SafeRequestStore[:net_ldap_count] = 7
        Gitlab::SafeRequestStore[:net_ldap_duration_s] = 1.2
      end

      it "returns the populated payload" do
        expect(described_class.payload).to eql(net_ldap_count: 7, net_ldap_duration_s: 1.2)
      end
    end
  end

  describe "#observe_event" do
    before do
      allow(subscriber).to receive(:current_transaction).and_return(transaction)
    end

    it "tracks LDAP request count" do
      expect(transaction).to receive(:increment)
        .with(:gitlab_net_ldap_total, 1, { name: "open" })
      expect(transaction).to receive(:increment)
        .with(:gitlab_net_ldap_total, 1, { name: "search" })

      subscriber.observe_event(event_1)
      subscriber.observe_event(event_2)
    end

    it "tracks LDAP request duration" do
      expect(transaction).to receive(:observe)
        .with(:gitlab_net_ldap_duration_seconds, 0.000321, { name: "open" })
      expect(transaction).to receive(:observe)
        .with(:gitlab_net_ldap_duration_seconds, 0.00012, { name: "search" })
      expect(transaction).to receive(:observe)
        .with(:gitlab_net_ldap_duration_seconds, 0.0053, { name: "search" })

      subscriber.observe_event(event_1)
      subscriber.observe_event(event_2)
      subscriber.observe_event(event_3)
    end

    it "stores per-request counters" do
      subscriber.observe_event(event_1)
      subscriber.observe_event(event_2)
      subscriber.observe_event(event_3)

      expect(Gitlab::SafeRequestStore[:net_ldap_count]).to eq(3)
      expect(Gitlab::SafeRequestStore[:net_ldap_duration_s]).to eq(0.005741) # (0.321 + 0.12 + 5.3) / 1000
    end
  end
end
