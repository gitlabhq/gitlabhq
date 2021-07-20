# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PendingBuild do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:build) { create(:ci_build, :created, pipeline: pipeline) }

  describe '.upsert_from_build!' do
    context 'another pending entry does not exist' do
      it 'creates a new pending entry' do
        result = described_class.upsert_from_build!(build)

        expect(result.rows.dig(0, 0)).to eq build.id
        expect(build.reload.queuing_entry).to be_present
      end
    end

    context 'when another queuing entry exists for given build' do
      before do
        create(:ci_pending_build, build: build, project: project)
      end

      it 'returns a build id as a result' do
        result = described_class.upsert_from_build!(build)

        expect(result.rows.dig(0, 0)).to eq build.id
      end
    end

    context 'when project does not have shared runner' do
      it 'sets instance_runners_enabled to false' do
        described_class.upsert_from_build!(build)

        expect(described_class.last.instance_runners_enabled).to be_falsey
      end
    end

    context 'when project has shared runner' do
      let_it_be(:runner) { create(:ci_runner, :instance) }

      context 'when ci_pending_builds_maintain_shared_runners_data is enabled' do
        it 'sets instance_runners_enabled to true' do
          described_class.upsert_from_build!(build)

          expect(described_class.last.instance_runners_enabled).to be_truthy
        end

        context 'when project is about to be deleted' do
          before do
            build.project.update!(pending_delete: true)
          end

          it 'sets instance_runners_enabled to false' do
            described_class.upsert_from_build!(build)

            expect(described_class.last.instance_runners_enabled).to be_falsey
          end
        end

        context 'when builds are disabled' do
          before do
            build.project.project_feature.update!(builds_access_level: false)
          end

          it 'sets instance_runners_enabled to false' do
            described_class.upsert_from_build!(build)

            expect(described_class.last.instance_runners_enabled).to be_falsey
          end
        end
      end

      context 'when ci_pending_builds_maintain_shared_runners_data is disabled' do
        before do
          stub_feature_flags(ci_pending_builds_maintain_shared_runners_data: false)
        end

        it 'sets instance_runners_enabled to false' do
          described_class.upsert_from_build!(build)

          expect(described_class.last.instance_runners_enabled).to be_falsey
        end
      end
    end
  end
end
