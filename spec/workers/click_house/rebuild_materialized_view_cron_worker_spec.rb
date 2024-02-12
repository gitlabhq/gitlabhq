# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::RebuildMaterializedViewCronWorker, feature_category: :database do
  it 'invokes the RebuildMaterializedViewService' do
    allow_next_instance_of(ClickHouse::RebuildMaterializedViewService) do |instance|
      allow(instance).to receive(:execute)
    end

    described_class.new.perform
  end
end
