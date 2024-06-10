# frozen_string_literal: true

require_relative "../rd_fast_spec_helper"

RSpec.describe RemoteDevelopment::Settings::ReconciliationIntervalSecondsValidator, :rd_fast, feature_category: :remote_development do
  include ResultMatchers

  let(:value) do
    {
      settings: {
        full_reconciliation_interval_seconds: loaded_full_reconciliation_interval_seconds,
        partial_reconciliation_interval_seconds: loaded_partial_reconciliation_interval_seconds
      }
    }
  end

  let(:loaded_partial_reconciliation_interval_seconds) { 10 }
  let(:loaded_full_reconciliation_interval_seconds) { 3600 }

  subject(:result) do
    described_class.validate(value)
  end

  context "when partial_reconciliation_interval_seconds and full_reconciliation_interval_seconds is valid" do
    it "return an ok Result containing the original value which was passed" do
      expect(result).to eq(Result.ok(value))
    end
  end

  context "when partial_reconciliation_interval_seconds is invalid" do
    context "when partial_reconciliation_interval_seconds is negative" do
      let(:loaded_partial_reconciliation_interval_seconds) { -10 }

      it "returns an err Result containing error details" do
        expect(result).to be_err_result do |message|
          expect(message)
            .to be_a RemoteDevelopment::Settings::Messages::SettingsPartialReconciliationIntervalSecondsValidationFailed
          message.context => { details: String => error_details }
          expect(error_details).to eq("Partial reconciliation interval must be greater than zero")
        end
      end
    end

    context "when partial_reconciliation_interval_seconds is greater than full_reconciliation_interval_seconds" do
      let(:loaded_partial_reconciliation_interval_seconds) { 4000 }

      it "returns an err Result containing error details" do
        expect(result).to be_err_result do |message|
          expect(message)
            .to be_a RemoteDevelopment::Settings::Messages::SettingsPartialReconciliationIntervalSecondsValidationFailed
          message.context => { details: String => error_details }
          expect(error_details).to eq("Partial reconciliation interval must be less than full reconciliation interval")
        end
      end
    end
  end

  context "when full_reconciliation_interval_seconds is invalid" do
    context "when full_reconciliation_interval_seconds is negative" do
      let(:loaded_full_reconciliation_interval_seconds) { -3600 }

      it "returns an err Result containing error details" do
        expect(result).to be_err_result do |message|
          expect(message)
            .to be_a(RemoteDevelopment::Settings::Messages::SettingsFullReconciliationIntervalSecondsValidationFailed)
          message.context => { details: String => error_details }
          expect(error_details).to eq("Full reconciliation interval must be greater than zero")
        end
      end
    end
  end
end
