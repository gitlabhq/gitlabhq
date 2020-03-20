# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::Alerts::DestroyService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:alert) { create(:prometheus_alert, project: project) }

  let(:service) { described_class.new(project, user, nil) }

  describe '#execute' do
    subject { service.execute(alert) }

    it 'deletes the alert' do
      expect(subject).to be_truthy

      expect(alert).to be_destroyed
    end
  end
end
