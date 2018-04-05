require 'spec_helper'

describe StatusEntity do
  let(:entity) { described_class.new(status) }

  let(:status) do
    Gitlab::Ci::Status::Success.new(double('object'), double('user'))
  end

  before do
    allow(status).to receive(:has_details?).and_return(true)
    allow(status).to receive(:details_path).and_return('some/path')
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains status details' do
      expect(subject).to include :text, :icon, :favicon, :label, :group, :tooltip
      expect(subject).to include :has_details, :details_path
      expect(subject[:favicon]).to match_asset_path('/assets/ci_favicons/favicon_status_success.ico')
    end

    it 'contains a dev namespaced favicon if dev env' do
      allow(Rails.env).to receive(:development?) { true }
      expect(entity.as_json[:favicon]).to match_asset_path('/assets/ci_favicons/dev/favicon_status_success.ico')
    end

    it 'contains a canary namespaced favicon if canary env' do
      stub_env('CANARY', 'true')
      expect(entity.as_json[:favicon]).to match_asset_path('/assets/ci_favicons/canary/favicon_status_success.ico')
    end
  end
end
