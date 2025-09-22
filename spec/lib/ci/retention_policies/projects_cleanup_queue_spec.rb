# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetentionPolicies::ProjectsCleanupQueue, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let_it_be(:project_0) { create(:project) }
  let_it_be(:project_1) { create(:project, ci_delete_pipelines_in_seconds: 2.weeks.to_i) }
  let_it_be(:project_2) { create(:project, ci_delete_pipelines_in_seconds: 2.weeks.to_i) }
  let_it_be(:project_3) { create(:project, ci_delete_pipelines_in_seconds: nil) }

  let_it_be(:old_pipeline_1) { create(:ci_pipeline, project: project_1, created_at: 1.year.ago, locked: :unlocked) }
  let_it_be(:new_pipeline_1) { create(:ci_pipeline, project: project_1, created_at: 1.week.ago, locked: :unlocked) }
  let_it_be(:old_pipeline_2) { create(:ci_pipeline, project: project_2, created_at: 1.month.ago, locked: :unlocked) }

  let_it_be(:untouched_pipeline_3) do
    create(:ci_pipeline, project: project_3, created_at: 1.month.ago, locked: :unlocked)
  end

  let(:queue) { described_class.instance }

  describe '#size and #list_all' do
    context 'when queue is empty' do
      it 'returns no items' do
        expect(queue.size).to eq(0)
        expect(queue.list_all).to eq([])
      end
    end

    context 'when queue has items' do
      before do
        queue.enqueue!(instance_double(Project, id: 1))
        queue.enqueue!(instance_double(Project, id: 2))
        queue.enqueue!(instance_double(Project, id: 3))
      end

      it 'returns the correct size' do
        expect(queue.size).to eq(3)
        expect(queue.list_all).to eq(%w[1 2 3])
      end
    end
  end

  describe '#enqueue!' do
    let(:project) { instance_double(Project, id: 100) }

    context 'when there are not items in the queue' do
      it 'adds the first item' do
        queue.enqueue!(project)

        expect(queue.size).to eq(1)

        expect(queue.list_all).to eq(['100'])
      end
    end

    context 'when there are items in the queue' do
      before do
        queue.enqueue!(instance_double(Project, id: 200))
      end

      it 'adds the item at the end' do
        queue.enqueue!(project)

        expect(queue.size).to eq(2)
        expect(queue.list_all).to eq(%w[200 100])
      end
    end
  end

  describe '#fetch_next_project_id!' do
    context 'when queue is empty' do
      it 'returns 0' do
        expect(queue.fetch_next_project_id!).to eq(0)
      end
    end

    context 'when queue has items' do
      before do
        queue.enqueue!(instance_double(Project, id: 1))
        queue.enqueue!(instance_double(Project, id: 2))
      end

      it 'pops the first item' do
        expect(queue.size).to eq(2)
        expect(queue.fetch_next_project_id!).to eq(1)
        expect(queue.size).to eq(1)
      end
    end
  end

  describe '#enqueue_projects!' do
    context 'when queue is empty' do
      before do
        allow(queue).to receive(:max_size).and_return(2)
      end

      it 'adds all projects with retention policy enabled' do
        expect { queue.enqueue_projects! }
          .to change { queue.list_all }
          .from([])
          .to([project_1.id.to_s, project_2.id.to_s])

        expect(queue.last_queued_project_id).to eq(project_2.id)
      end
    end

    context 'when queue has limited space left' do
      before do
        allow(queue).to receive(:max_size).and_return(2)

        queue.enqueue!(project_1)
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class::LAST_QUEUED_KEY, project_1.id)
        end
      end

      it 'adds projects up to the limit' do
        expect { queue.enqueue_projects! }
          .to change { queue.list_all }.from([project_1.id.to_s]).to([project_1, project_2].map(&:id).map(&:to_s))
          .and change { queue.last_queued_project_id }.from(project_1.id).to(project_2.id)
      end

      context 'when fetched projects are fewer than the available space' do
        before do
          allow(queue).to receive(:max_size).and_return(100)
        end

        it 'adds projects and resets the last_queued_project_id' do
          expect { queue.enqueue_projects! }
            .to change { queue.list_all }
              .from([project_1.id.to_s])
              .to([project_1, project_2].map(&:id).map(&:to_s))
            .and change { queue.last_queued_project_id }
              .from(project_1.id)
              .to(0)
        end
      end
    end

    context 'when queue is maxed out' do
      before do
        allow(queue).to receive_messages(max_size: 2, size: 2)
      end

      it 'does nothing' do
        expect { queue.enqueue_projects! }.to not_change { queue.list_all }
      end
    end
  end
end
