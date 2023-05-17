# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildPrepareWorker, feature_category: :continuous_integration do
  subject { described_class.new.perform(build_id) }

  context 'build exists' do
    let(:build) { create(:ci_build) }
    let(:build_id) { build.id }
    let(:service) { double(execute: true) }

    it 'calls the prepare build service' do
      expect(Ci::PrepareBuildService).to receive(:new).with(build).and_return(service)
      expect(service).to receive(:execute).once

      subject
    end
  end

  context 'build does not exist' do
    let(:build_id) { -1 }

    it 'does not attempt to prepare the build' do
      expect(Ci::PrepareBuildService).not_to receive(:new)

      subject
    end
  end
end
