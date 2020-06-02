# frozen_string_literal: true

require 'spec_helper'

describe CreateEvidenceWorker do
  let(:release) { create(:release) }

  it 'creates a new Evidence record' do
    expect_next_instance_of(::Releases::CreateEvidenceService, release) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    expect { described_class.new.perform(release.id) }.to change(Releases::Evidence, :count).by(1)
  end
end
