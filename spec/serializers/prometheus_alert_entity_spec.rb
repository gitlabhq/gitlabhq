# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PrometheusAlertEntity do
  let(:user) { build_stubbed(:user) }
  let(:prometheus_alert) { build_stubbed(:prometheus_alert) }
  let(:request) { double('prometheus_alert', current_user: user) }
  let(:entity) { described_class.new(prometheus_alert, request: request) }

  subject { entity.as_json }

  context 'when user can read prometheus alerts' do
    before do
      prometheus_alert.project.add_maintainer(user)
    end

    it 'exposes prometheus_alert attributes' do
      expect(subject).to include(:id, :title, :query, :operator, :threshold, :runbook_url)
    end
  end
end
