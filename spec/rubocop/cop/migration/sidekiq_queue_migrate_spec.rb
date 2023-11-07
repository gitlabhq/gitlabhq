# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/sidekiq_queue_migrate'

RSpec.describe RuboCop::Cop::Migration::SidekiqQueueMigrate do
  def source(meth = 'change')
    "def #{meth}; sidekiq_queue_migrate 'queue', to: 'new_queue'; end"
  end

  context 'when in a regular migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
      allow(cop).to receive(:in_post_deployment_migration?).and_return(false)
    end

    %w[up down change any_other_method].each do |method_name|
      it "registers an offense when sidekiq_queue_migrate is used in ##{method_name}" do
        expect_offense(<<~RUBY)
          def #{method_name}
            sidekiq_queue_migrate 'queue', to: 'new_queue'
            ^^^^^^^^^^^^^^^^^^^^^ `sidekiq_queue_migrate` must only be used in post-deployment migrations
          end
        RUBY
      end
    end
  end

  context 'when in a post-deployment migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
      allow(cop).to receive(:in_post_deployment_migration?).and_return(true)
    end

    it 'registers no offense' do
      expect_no_offenses(source)
    end
  end

  context 'when outside of a migration' do
    it 'registers no offense' do
      expect_no_offenses(source)
    end
  end
end
