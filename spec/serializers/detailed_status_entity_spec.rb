# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DetailedStatusEntity do
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
      expect(subject[:favicon]).to match_asset_path('/assets/ci_favicons/favicon_status_success.png')
    end
  end
end
