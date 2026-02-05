# frozen_string_literal: true

RSpec.shared_examples 'job is dropped with failure reason' do |failure_reason|
  it 'changes status' do
    service.execute
    job.reload

    expect(job).to be_failed
    expect(job.failure_reason).to eq(failure_reason)
  end

  context 'when job has data integrity problem' do
    it 'drops the job and logs the reason' do
      allow(::Gitlab::Ci::Build::Status::Reason).to receive(:fabricate).and_raise(StandardError.new)

      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(anything, a_hash_including(build_id: job.id))
        .once
        .and_call_original

      service.execute
      job.reload

      expect(job).to be_failed
      expect(job.failure_reason).to eq('data_integrity_failure')
    end
  end
end

RSpec.shared_examples 'job is canceled' do
  it 'changes status' do
    service.execute
    job.reload

    expect(job).to be_canceled
  end
end

RSpec.shared_examples 'job is unchanged' do
  it 'does not change status' do
    expect { service.execute }.not_to change { job.status }
  end
end

RSpec.shared_examples 'when invalid dooms the job bypassing validations' do
  it 'does not change status' do
    allow_next_found_instance_of(Ci::Build) do |build|
      allow(build).to receive(:drop!).and_raise(StateMachines::InvalidTransition)
    end

    expect(Gitlab::ErrorTracking)
      .to receive(:track_exception)
      .with(anything, a_hash_including(build_id: job.id))
      .once
      .and_call_original

    service.execute
    job.reload

    expect(job).to be_failed
    expect(job.failure_reason).to eq('data_integrity_failure')
  end
end
