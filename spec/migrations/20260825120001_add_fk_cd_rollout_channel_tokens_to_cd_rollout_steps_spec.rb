# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddFkCdRolloutChannelTokensToCdRolloutSteps, migration: :gitlab_main,
  feature_category: :continuous_delivery do
  let(:connection) { described_class.new.connection }
  let(:table_name) { :cd_rollout_channel_tokens }

  def foreign_key
    connection.foreign_keys(table_name).find { |fk| fk.column == 'rollout_step_id' }
  end

  describe '#up', :aggregate_failures do
    it 'adds the foreign key on rollout_step_id' do
      expect { migrate! }.to change { foreign_key }.from(nil)

      expect(foreign_key.to_table).to eq('cd_rollout_steps')
    end

    it 'nullifies rollout_step_id on delete, rather than cascading' do
      migrate!

      # A channel token is a durable handle for pushing into AutoFlow; deleting
      # the step it was opened for should not delete the token itself.
      expect(foreign_key.on_delete).to eq(:nullify)
    end
  end

  describe '#down' do
    it 'removes the foreign key on rollout_step_id' do
      migrate!
      schema_migrate_down!

      expect(foreign_key).to be_nil
    end
  end
end
