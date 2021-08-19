# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PendingBuild do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:build) { create(:ci_build, :created, pipeline: pipeline) }

  describe 'associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to belong_to :build }
    it { is_expected.to belong_to :namespace }
  end

  describe 'scopes' do
    describe '.with_instance_runners' do
      subject(:pending_builds) { described_class.with_instance_runners }

      let!(:pending_build_1) { create(:ci_pending_build, instance_runners_enabled: false) }

      context 'when pending builds cannot be picked up by runner' do
        it 'returns an empty collection of pending builds' do
          expect(pending_builds).to be_empty
        end
      end

      context 'when pending builds can be picked up by runner' do
        let!(:pending_build_2) { create(:ci_pending_build) }

        it 'returns matching pending builds' do
          expect(pending_builds).to contain_exactly(pending_build_2)
        end
      end
    end
  end

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
