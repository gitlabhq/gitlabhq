# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::CommitStatusPreloader do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  let_it_be(:build1) { create(:ci_build, :tags, pipeline: pipeline) }
  let_it_be(:build2) { create(:ci_build, :tags, pipeline: pipeline) }
  let_it_be(:bridge1) { create(:ci_bridge, pipeline: pipeline) }
  let_it_be(:bridge2) { create(:ci_bridge, pipeline: pipeline) }
  let_it_be(:generic_commit_status1) { create(:generic_commit_status, pipeline: pipeline) }
  let_it_be(:generic_commit_status2) { create(:generic_commit_status, pipeline: pipeline) }

  describe '#execute' do
    let(:relations) { %i[pipeline metadata tags job_artifacts_archive { downstream_pipeline: [:user] }] }
    let(:statuses) { CommitStatus.where(commit_id: pipeline.id).all }

    subject(:execute) { described_class.new(statuses).execute(relations) }

    it 'prevents N+1 for specified relations', :use_sql_query_cache do
      execute

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        call_each_relation(statuses.sample(3))
      end

      expect do
        call_each_relation(statuses)
      end.to issue_same_number_of_queries_as(control)
    end

    context 'when given an invalid relation' do
      let(:relations) { [1] }

      it { expect { execute }.to raise_error(ArgumentError, "Invalid relation: 1") }
    end

    private

    def call_each_relation(statuses)
      statuses.each do |status|
        relations.each { |relation| status.public_send(relation) if status.respond_to?(relation) }
      end
    end
  end
end
