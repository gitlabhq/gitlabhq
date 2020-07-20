# frozen_string_literal: true

RSpec.shared_examples 'include import workers modules' do
  it { expect(described_class).to include_module(ApplicationWorker) }
  it { expect(described_class).to include_module(Gitlab::JiraImport::QueueOptions) }

  if described_class == Gitlab::JiraImport::Stage::StartImportWorker
    it { expect(described_class).to include_module(ProjectStartImport) }
    it { expect(described_class).to include_module(ProjectImportOptions) }
  else
    it { expect(described_class).to include_module(Gitlab::JiraImport::ImportWorker) }
  end
end

RSpec.shared_examples 'does not advance to next stage' do
  it 'does not advance to next stage' do
    expect(Gitlab::JiraImport::AdvanceStageWorker).not_to receive(:perform_async)

    described_class.new.perform(project.id)
  end
end

RSpec.shared_examples 'cannot do Jira import' do
  it 'does not advance to next stage' do
    worker = described_class.new
    expect(worker).not_to receive(:import)

    worker.perform(project.id)
  end
end

RSpec.shared_examples 'advance to next stage' do |next_stage|
  let(:job_waiter) { Gitlab::JobWaiter.new(2, 'some-job-key') }

  it "advances to #{next_stage} stage" do
    expect(Gitlab::JobWaiter).to receive(:new).and_return(job_waiter)
    expect(Gitlab::JiraImport::AdvanceStageWorker).to receive(:perform_async).with(project.id, { job_waiter.key => job_waiter.jobs_remaining }, next_stage.to_sym).and_return([])

    described_class.new.perform(project.id)
  end
end
