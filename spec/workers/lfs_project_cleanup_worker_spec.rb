require 'spec_helper'

describe LfsProjectCleanupWorker do
  let(:project) { create(:project) }
  subject(:worker) { described_class.new }

  it 'calls service to cleanup unreferenced LFS pointers' do
    expect_any_instance_of(LfsCleanupService).to receive(:remove_unreferenced)

    subject.perform(project.id)
  end
end
