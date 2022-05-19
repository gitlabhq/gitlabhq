# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prometheus::CreateDefaultAlertsWorker do
  let_it_be(:project) { create(:project) }

  subject { described_class.new.perform(project.id) }

  it 'does nothing' do
    expect { subject }.not_to change { PrometheusAlert.count }
  end
end
