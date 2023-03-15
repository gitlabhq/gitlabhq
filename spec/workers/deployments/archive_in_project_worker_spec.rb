# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::ArchiveInProjectWorker, feature_category: :continuous_delivery do
  subject { described_class.new.perform(deployment&.project_id) }

  describe '#perform' do
    let(:deployment) { create(:deployment, :success) }

    it 'executes Deployments::ArchiveInProjectService' do
      expect(Deployments::ArchiveInProjectService)
          .to receive(:new).with(deployment.project, nil).and_call_original

      subject
    end
  end
end
