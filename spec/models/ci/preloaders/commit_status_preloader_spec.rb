# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Preloaders::CommitStatusPreloader, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  let_it_be(:build1) { create(:ci_build, :tags, :artifacts, pipeline: pipeline) }
  let_it_be(:build2) { create(:ci_build, :tags, pipeline: pipeline) }
  let_it_be(:bridge1) { create(:ci_bridge, pipeline: pipeline) }
  let_it_be(:bridge2) { create(:ci_bridge, pipeline: pipeline) }
  let_it_be(:generic_commit_status1) { create(:generic_commit_status, pipeline: pipeline) }
  let_it_be(:generic_commit_status2) { create(:generic_commit_status, pipeline: pipeline) }

  describe '#execute' do
    let(:relations) do
      [:pipeline, :job_definition, :job_artifacts_archive, { downstream_pipeline: [:user] }]
    end

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

    # Ci::Build and Ci::Bridge redeclare these associations, so each class has its
    # own reflection. Rails batches loaders that build the same query, which is
    # internal behaviour, so pin the query count as well as the instance identity.
    it 'loads associations CommitStatus defines once for all statuses' do
      recorder = ActiveRecord::QueryRecorder.new { described_class.new(statuses).execute([:project, :pipeline]) }

      expect(recorder.log.grep(/FROM "projects"/)).to have_attributes(size: 1)
      expect(recorder.log.grep(/FROM "p_ci_pipelines"/)).to have_attributes(size: 1)
      expect(statuses).to all(satisfy { |status| status.association(:project).loaded? })
      expect(statuses.map(&:project).map(&:object_id).uniq).to have_attributes(size: 1)
      expect(statuses.map(&:pipeline).map(&:object_id).uniq).to have_attributes(size: 1)
    end

    it 'loads associations only some classes define once for all statuses that define them' do
      recorder = ActiveRecord::QueryRecorder.new { described_class.new(statuses).execute([:job_definition]) }

      expect(recorder.log.grep(/FROM "p_ci_job_definition_instances"/)).to have_attributes(size: 1)
      expect(statuses.reject { |status| status.is_a?(GenericCommitStatus) })
        .to all(satisfy { |status| status.association(:job_definition).loaded? })
    end

    it 'splits multi-key hashes so each association is routed on its own' do
      described_class.new(statuses).execute([{ project: :route, job_artifacts: :project }])

      expect(statuses.find { |status| status.id == build1.id }.association(:job_artifacts)).to be_loaded
      expect(statuses).to all(satisfy { |status| status.project.association(:route).loaded? })
    end

    it 'applies the given scope to the preloaded records' do
      described_class.new(statuses).execute([:project], scope: ActiveRecord::Relation::StrictLoadingScope)

      expect(statuses.first.project).to be_strict_loading
    end

    it 'raises for association names no commit status class defines' do
      expect { described_class.new(statuses).execute([:job_definitions]) }
        .to raise_error(ArgumentError, /Unknown associations for CommitStatus preload: \[:job_definitions\]/)
    end

    # Whether the report raises is decided by Gitlab::ErrorTracking, which does not
    # outside development and test. Stub it out to cover what this class owns: the
    # rest of the list still loads once an unknown name has been reported.
    context 'when the report does not raise' do
      before do
        allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
      end

      it 'reports the unknown name, skips it and preloads the rest' do
        described_class.new(statuses).execute([:job_definitions, :project])

        expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception)
          .with(an_instance_of(ArgumentError))
        expect(statuses).to all(satisfy { |status| status.association(:project).loaded? })
      end
    end

    context 'when given an invalid relation' do
      let(:relations) { [1] }

      it { expect { execute }.to raise_error(ArgumentError, "Invalid relation: 1") }
    end

    private

    def call_each_relation(statuses)
      statuses.each do |status|
        relations.each do |relation|
          name = relation.is_a?(Hash) ? relation.each_key.first : relation
          status.public_send(name) if status.respond_to?(name)
        end
      end
    end
  end
end
