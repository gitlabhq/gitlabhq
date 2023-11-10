# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RecordTargetPlatformsWorker, feature_category: :activation do
  include ExclusiveLeaseHelpers

  let_it_be(:swift) { create(:programming_language, name: 'Swift') }
  let_it_be(:objective_c) { create(:programming_language, name: 'Objective-C') }
  let_it_be(:project) { create(:project, :repository, detected_repository_languages: true) }

  let(:worker) { described_class.new }
  let(:service_result) { %w[ios osx watchos] }
  let(:service_double) { instance_double(Projects::RecordTargetPlatformsService, execute: service_result) }
  let(:lease_key) { "#{described_class.name.underscore}:#{project.id}" }
  let(:lease_timeout) { described_class::LEASE_TIMEOUT }

  subject(:perform) { worker.perform(project.id) }

  before do
    stub_exclusive_lease(lease_key, timeout: lease_timeout)
  end

  shared_examples 'performs detection' do |detector_service_class|
    let(:service_double) { instance_double(detector_service_class, execute: service_result) }

    it "creates and executes a #{detector_service_class} instance for the project", :aggregate_failures do
      expect(Projects::RecordTargetPlatformsService).to receive(:new)
        .with(project, detector_service_class) { service_double }
      expect(service_double).to receive(:execute)

      perform
    end

    it 'logs extra metadata on done', :aggregate_failures do
      expect(Projects::RecordTargetPlatformsService).to receive(:new)
        .with(project, detector_service_class) { service_double }
      expect(worker).to receive(:log_extra_metadata_on_done).with(:target_platforms, service_result)

      perform
    end
  end

  shared_examples 'does nothing' do
    it 'does nothing' do
      expect(Projects::RecordTargetPlatformsService).not_to receive(:new)

      perform
    end
  end

  context 'when project uses Swift programming language' do
    let!(:repository_language) { create(:repository_language, project: project, programming_language: swift) }

    include_examples 'performs detection', Projects::AppleTargetPlatformDetectorService
  end

  context 'when project uses Objective-C programming language' do
    let!(:repository_language) { create(:repository_language, project: project, programming_language: objective_c) }

    include_examples 'performs detection', Projects::AppleTargetPlatformDetectorService
  end

  context 'when the project does not contain programming languages for Apple platforms' do
    it_behaves_like 'does nothing'
  end

  context 'when project is not found' do
    it 'does nothing' do
      expect(Projects::RecordTargetPlatformsService).not_to receive(:new)

      worker.perform(non_existing_record_id)
    end
  end

  context 'when exclusive lease cannot be obtained' do
    before do
      stub_exclusive_lease_taken(lease_key)
    end

    it_behaves_like 'does nothing'
  end

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'overrides #lease_release? to return false' do
    expect(worker.send(:lease_release?)).to eq false
  end
end
