# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe RemoteDevelopment::Settings::NetworkPolicyEgressValidator, :rd_fast, feature_category: :remote_development do
  include ResultMatchers

  let(:context) do
    {
      requested_setting_names: [:network_policy_egress],
      settings: {
        network_policy_egress: network_policy_egress
      }
    }
  end

  let(:network_policy_egress) do
    [{
      allow: "0.0.0.0/0",
      except: %w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16]
    }]
  end

  subject(:result) do
    described_class.validate(context)
  end

  context "when network_policy_egress is valid" do
    it "return an ok Result containing the original context which was passed" do
      expect(result).to eq(Gitlab::Fp::Result.ok(context))
    end
  end

  context "when network_policy_egress is invalid" do
    context "when network_policy_egress is invalid because it omits the allowed ip list" do
      let(:network_policy_egress) do
        [{
          except: %w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16]
        }]
      end

      it "returns an err Result highlighting validation failure" do
        expect(result).to be_err_result do |message|
          expect(message)
            .to be_a RemoteDevelopment::Settings::Messages::SettingsNetworkPolicyEgressValidationFailed
          message.content => { details: String => error_details }
          expect(error_details).to eq("property '/0' is missing required keys: allow")
        end
      end
    end
  end

  context "when requested_setting_names does not include network_policy_egress" do
    let(:context) do
      {
        requested_setting_names: [:some_other_setting]
      }
    end

    it "returns an ok result with the original context" do
      expect(result).to be_ok_result(context)
    end
  end
end
