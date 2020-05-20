# frozen_string_literal: true

RSpec.shared_examples 'a pages cronjob scheduling jobs with context' do |scheduled_worker_class|
  let(:worker) { described_class.new }

  context 'with RequestStore enabled', :request_store do
    it 'does not cause extra queries for multiple domains' do
      control = ActiveRecord::QueryRecorder.new { worker.perform }

      extra_domain

      expect { worker.perform }.not_to exceed_query_limit(control)
    end
  end

  it 'schedules the renewal with a context' do
    extra_domain

    worker.perform

    expect(scheduled_worker_class.jobs.last).to include("meta.project" => extra_domain.project.full_path)
  end
end
