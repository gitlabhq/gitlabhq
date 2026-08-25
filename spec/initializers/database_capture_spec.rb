# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'database capture', feature_category: :database do
  let(:database_names) { %w[main ci] }
  let(:capture_task) { instance_double(Gitlab::Database::Capture::Task) }
  let(:background_task) { instance_double(Gitlab::BackgroundTask) }

  before do
    allow(Gitlab::Database).to receive(:database_base_models).and_return(
      database_names.index_with { |_| class_double(ActiveRecord::Base) }
    )
    allow(Gitlab::Database::Capture::Task).to receive(:new).and_return(capture_task)
    allow(Gitlab::BackgroundTask).to receive(:new).and_return(background_task)
    allow(background_task).to receive(:start)
  end

  subject(:run_initializer) do
    load rails_root_join('config/initializers/database_capture.rb')
  end

  context 'when runtime is an application' do
    before do
      allow(Gitlab::Runtime).to receive(:application?).and_return(true)
    end

    it 'starts database capture tasks for each database' do
      database_names.each do |database_name|
        expect(Gitlab::Database::Capture::Task).to receive(:new).with(database_name: database_name)
      end

      expect(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start).and_yield

      run_initializer
    end
  end

  context 'when runtime is not an application' do
    before do
      allow(Gitlab::Runtime).to receive(:application?).and_return(false)
    end

    it 'does not start database capture tasks' do
      expect(Gitlab::Cluster::LifecycleEvents).not_to receive(:on_worker_start)

      run_initializer
    end
  end
end
