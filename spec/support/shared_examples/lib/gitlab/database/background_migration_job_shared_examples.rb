# frozen_string_literal: true

RSpec.shared_examples 'marks background migration job records' do
  it 'marks each job record as succeeded after processing' do
    create(
      :background_migration_job,
      class_name: "::#{described_class.name.demodulize}",
      arguments: arguments
    )

    expect(::Gitlab::Database::BackgroundMigrationJob).to receive(:mark_all_as_succeeded).and_call_original

    expect do
      subject.perform(*arguments)
    end.to change { ::Gitlab::Database::BackgroundMigrationJob.succeeded.count }.from(0).to(1)
  end

  it 'returns the number of job records marked as succeeded' do
    create(
      :background_migration_job,
      class_name: "::#{described_class.name.demodulize}",
      arguments: arguments
    )

    jobs_updated = subject.perform(*arguments)

    expect(jobs_updated).to eq(1)
  end
end

RSpec.shared_examples 'finalized background migration' do |worker_class|
  it 'processed the scheduled sidekiq queue', :allow_unrouted_sidekiq_calls do
    queued = Sidekiq::ScheduledSet
      .new
      .select do |scheduled|
        scheduled.klass == worker_class.name &&
          scheduled.args.first == job_class_name
      end
    expect(queued.size).to eq(0)
  end

  it 'processed the async sidekiq queue', :allow_unrouted_sidekiq_calls do
    queued = Sidekiq::Queue.new(worker_class.name)
      .select { |scheduled| scheduled.klass == job_class_name }
    expect(queued.size).to eq(0)
  end

  include_examples 'removed tracked jobs', 'pending'
end

RSpec.shared_examples 'finalized tracked background migration' do |worker_class|
  include_examples 'finalized background migration', worker_class
  include_examples 'removed tracked jobs', 'succeeded'
end

RSpec.shared_examples 'removed tracked jobs' do |status|
  it "removes '#{status}' tracked jobs" do
    jobs = Gitlab::Database::BackgroundMigrationJob
      .where(status: Gitlab::Database::BackgroundMigrationJob.statuses[status])
      .for_migration_class(job_class_name)
    expect(jobs).to be_empty
  end
end

RSpec.shared_examples 'retained tracked jobs' do |status|
  it "retains '#{status}' tracked jobs" do
    jobs = Gitlab::Database::BackgroundMigrationJob
      .where(status: Gitlab::Database::BackgroundMigrationJob.statuses[status])
      .for_migration_class(job_class_name)
    expect(jobs).to be_present
  end
end
