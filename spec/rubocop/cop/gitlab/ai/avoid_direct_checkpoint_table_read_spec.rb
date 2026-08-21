# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/ai/avoid_direct_checkpoint_table_read'

RSpec.describe RuboCop::Cop::Gitlab::Ai::AvoidDirectCheckpointTableRead, feature_category: :duo_agent_platform do
  offense_message = 'Avoid reading the full-row `Ai::DuoWorkflows::Checkpoint` table directly outside the ' \
    'Workflow/Checkpoint models -- `duo_workflow_write_incremental_only` stops writing this table, ' \
    'so this will silently return nil/empty. Use `Workflow#checkpoint_headers`, ' \
    '`#latest_checkpoint_header`, or `#reconstructed_channel_values` instead. ' \
    'See https://gitlab.com/gitlab-org/gitlab/-/work_items/612557.'

  shared_examples 'raises rubocop offense' do |code|
    it "registers an offense for #{code}" do
      expect_offense(<<~RUBY)
        #{code}
        #{'^' * code.length} #{offense_message}
      RUBY
    end
  end

  context 'when reading from the checkpoints association' do
    it_behaves_like 'raises rubocop offense', 'workflow.checkpoints.latest'
    it_behaves_like 'raises rubocop offense', 'workflow.checkpoints.earliest(checkpoint_ns: ns)'
    it_behaves_like 'raises rubocop offense', 'workflow.checkpoints.order_by_created_at_desc'
    it_behaves_like 'raises rubocop offense', 'workflow.checkpoints.ordered_with_writes'
    it_behaves_like 'raises rubocop offense', 'workflow.checkpoints.with_checkpoint_writes'
    it_behaves_like 'raises rubocop offense', '@workflow.checkpoints.latest'
  end

  context 'when reading via safe navigation' do
    it_behaves_like 'raises rubocop offense', 'workflow&.checkpoints.latest'
    it_behaves_like 'raises rubocop offense', 'workflow.checkpoints&.latest'
    it_behaves_like 'raises rubocop offense', 'workflow&.basic_checkpoints'
  end

  context 'when reading basic_checkpoints' do
    it_behaves_like 'raises rubocop offense', 'workflow.basic_checkpoints'

    it 'registers an offense on the basic_checkpoints call within a longer chain' do
      expect_offense(<<~RUBY)
        workflow.basic_checkpoints.empty?
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense_message}
      RUBY
    end
  end

  it 'does not raise an offense for the write path' do
    expect_no_offenses(<<~RUBY)
      workflow.checkpoints.new(checkpoint_attributes)
      workflow.checkpoints.exists?
    RUBY
  end

  it 'does not raise an offense for the header/blob read path' do
    expect_no_offenses(<<~RUBY)
      workflow.checkpoint_headers.latest_checkpoint_header
      workflow.reconstructed_channel_values(header)
    RUBY
  end

  it 'does not raise an offense for unrelated method chains' do
    expect_no_offenses(<<~RUBY)
      pipeline.builds.latest
      workflow.checkpoints.new(checkpoint_attributes)
    RUBY
  end
end
