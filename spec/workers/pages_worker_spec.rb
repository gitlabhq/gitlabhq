# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesWorker, :sidekiq_inline, feature_category: :pages do
  let_it_be(:ci_build) { create(:ci_build) }

  context 'when called with the deploy action' do
    it 'calls UpdatePagesService' do
      expect_next_instance_of(Projects::UpdatePagesService, ci_build.project, ci_build) do |service|
        expect(service).to receive(:execute)
      end

      described_class.perform_async(:deploy, ci_build.id)
    end
  end

  context 'when called with any other action' do
    it 'does nothing' do
      expect_next_instance_of(described_class) do |job_class|
        expect(job_class).not_to receive(:foo)
        expect(job_class).not_to receive(:deploy)
      end

      described_class.perform_async(:foo)
    end
  end
end
