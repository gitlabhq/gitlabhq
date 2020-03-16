# frozen_string_literal: true

# Expects the calling spec to define:
# - uploader_class
# - model_class
# - mounted_as
RSpec.shared_examples 'enqueue upload migration jobs in batch' do |batch:|
  def run(task)
    args = [uploader_class.to_s, model_class.to_s, mounted_as].compact
    run_rake_task(task, *args)
  end

  it 'migrates local storage to remote object storage' do
    expect(ObjectStorage::MigrateUploadsWorker)
      .to receive(:perform_async).exactly(batch).times
      .and_return("A fake job.")

    run('gitlab:uploads:migrate')
  end

  it 'migrates remote object storage to local storage' do
    expect(Upload).to receive(:where).exactly(batch + 1).times { Upload.all }
    expect(ObjectStorage::MigrateUploadsWorker)
      .to receive(:perform_async)
      .with(anything, model_class.name, mounted_as, ObjectStorage::Store::LOCAL)
      .exactly(batch).times
      .and_return("A fake job.")

    run('gitlab:uploads:migrate_to_local')
  end
end
