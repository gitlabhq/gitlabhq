# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pages::LegacyStorageLease do
  let(:project) { create(:project) }

  let(:implementation) do
    Class.new do
      include ::Pages::LegacyStorageLease

      attr_reader :project

      def initialize(project)
        @project = project
      end

      def execute
        try_obtain_lease do
          execute_unsafe
        end
      end

      def execute_unsafe
        true
      end
    end
  end

  let(:service) { implementation.new(project) }

  it 'allows method to be executed' do
    expect(service).to receive(:execute_unsafe).and_call_original

    expect(service.execute).to eq(true)
  end

  context 'when another service holds the lease for the same project' do
    around do |example|
      implementation.new(project).try_obtain_lease do
        example.run
      end
    end

    it 'does not run guarded method' do
      expect(service).not_to receive(:execute_unsafe)

      expect(service.execute).to eq(nil)
    end
  end

  context 'when another service holds the lease for the different project' do
    around do |example|
      implementation.new(create(:project)).try_obtain_lease do
        example.run
      end
    end

    it 'allows method to be executed' do
      expect(service).to receive(:execute_unsafe).and_call_original

      expect(service.execute).to eq(true)
    end
  end
end
