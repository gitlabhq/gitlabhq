# frozen_string_literal: true
#
require 'spec_helper'

RSpec.describe PartitionCreationWorker do
  subject { described_class.new.perform }

  let(:management_worker) { double }

  describe '#perform' do
    it 'forwards to the Database::PartitionManagementWorker' do
      expect(Database::PartitionManagementWorker).to receive(:new).and_return(management_worker)
      expect(management_worker).to receive(:perform)

      subject
    end
  end
end
