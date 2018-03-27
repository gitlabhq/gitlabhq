require 'spec_helper'

describe RepositoryCheck::ClearWorker do
  it 'clears repository check columns' do
    project = create(:project)
    project.update_columns(
      last_repository_check_failed: true,
      last_repository_check_at: Time.now
    )

    described_class.new.perform
    project.reload

    expect(project.last_repository_check_failed).to be_nil
    expect(project.last_repository_check_at).to be_nil
  end
end
