# frozen_string_literal: true

RSpec.shared_examples 'marks background migration job records' do
  it 'marks each job record as succeeded after processing' do
    create(:background_migration_job, class_name: "::#{described_class.name}",
           arguments: arguments)

    expect(::Gitlab::Database::BackgroundMigrationJob).to receive(:mark_all_as_succeeded).and_call_original

    expect do
      subject.perform(*arguments)
    end.to change { ::Gitlab::Database::BackgroundMigrationJob.succeeded.count }.from(0).to(1)
  end

  it 'returns the number of job records marked as succeeded' do
    create(:background_migration_job, class_name: "::#{described_class.name}",
           arguments: arguments)

    jobs_updated = subject.perform(*arguments)

    expect(jobs_updated).to eq(1)
  end
end
