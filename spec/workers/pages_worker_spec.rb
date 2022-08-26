# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesWorker, :sidekiq_inline do
  let(:project) { create(:project) }
  let(:ci_build) { create(:ci_build, project: project) }

  it 'calls UpdatePagesService' do
    expect_next_instance_of(Projects::UpdatePagesService, project, ci_build) do |service|
      expect(service).to receive(:execute)
    end

    described_class.perform_async(:deploy, ci_build.id)
  end
end
