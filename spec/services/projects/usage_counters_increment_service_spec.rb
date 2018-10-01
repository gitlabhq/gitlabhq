# frozen_string_literal: true

require 'spec_helper'

describe Projects::UsageCountersIncrementService do
  let(:project) { create(:usage_counters) }

  subject(:service) { described_class.new(project) }

  context '#execute' do
    context 'when single attribute is passed' do
      it 'increments attribute' do
        expect do
          service.execute(:web_ide_commits)
        end.to change { project.usage_counters.reload.web_ide_commits }.from(0).to(1)
      end
    end

    context 'when array is passed' do
      it 'increments specified attributes' do
        expect do
          service.execute(%i(web_ide_commits))
        end.to change { project.usage_counters.reload.web_ide_commits }.from(0).to(1)
      end
    end
  end
end
