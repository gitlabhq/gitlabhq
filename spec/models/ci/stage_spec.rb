# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Stage, :models do
  let_it_be(:pipeline) { create(:ci_empty_pipeline) }

  let(:stage) { create(:ci_stage_entity, pipeline: pipeline, project: pipeline.project) }

  it_behaves_like 'having unique enum values'

  describe 'associations' do
    before do
      create(:ci_build, stage_id: stage.id)
      create(:commit_status, stage_id: stage.id)
    end

    describe '#statuses' do
      it 'returns all commit statuses' do
        expect(stage.statuses.count).to be 2
      end
    end

    describe '#builds' do
      it 'returns only builds' do
        expect(stage.builds).to be_one
      end
    end
  end

  describe '.by_name' do
    it 'finds stages by name' do
      a = create(:ci_stage_entity, name: 'a')
      b = create(:ci_stage_entity, name: 'b')
      c = create(:ci_stage_entity, name: 'c')

      expect(described_class.by_name('a')).to contain_exactly(a)
      expect(described_class.by_name('b')).to contain_exactly(b)
      expect(described_class.by_name(%w[a c])).to contain_exactly(a, c)
    end
  end

  describe '#status' do
    context 'when stage is pending' do
      let(:stage) { create(:ci_stage_entity, status: 'pending') }

      it 'has a correct status value' do
        expect(stage.status).to eq 'pending'
      end
    end

    context 'when stage is success' do
      let(:stage) { create(:ci_stage_entity, status: 'success') }

      it 'has a correct status value' do
        expect(stage.status).to eq 'success'
      end
    end

    context 'when stage status is not defined' do
      before do
        stage.update_column(:status, nil)
      end

      it 'sets the default value' do
        expect(described_class.find(stage.id).status)
          .to eq 'created'
      end
    end
  end

  describe '#set_status' do
    where(:from_status, :to_status) do
      from_status_names = described_class.state_machines[:status].states.map(&:name)
      to_status_names = from_status_names - [:created] # we never want to transition into created

      from_status_names.product(to_status_names)
    end

    with_them do
      it do
        stage.status = from_status.to_s

        if from_status != to_status
          expect(stage.set_status(to_status.to_s))
            .to eq(true)
        else
          expect(stage.set_status(to_status.to_s))
            .to eq(false), "loopback transitions are not allowed"
        end
      end
    end
  end

  describe '#update_status' do
    context 'when stage objects needs to be updated' do
      before do
        create(:ci_build, :success, stage_id: stage.id)
        create(:ci_build, :running, stage_id: stage.id)
      end

      it 'updates stage status correctly' do
        expect { stage.update_legacy_status }
          .to change { stage.reload.status }
          .to eq 'running'
      end
    end

    context 'when stage has only created builds' do
      let(:stage) { create(:ci_stage_entity, status: :created) }

      before do
        create(:ci_build, :created, stage_id: stage.id)
      end

      it 'updates status to skipped' do
        expect(stage.reload.status).to eq 'created'
      end
    end

    context 'when stage is skipped because of skipped builds' do
      before do
        create(:ci_build, :skipped, stage_id: stage.id)
      end

      it 'updates status to skipped' do
        expect { stage.update_legacy_status }
          .to change { stage.reload.status }
          .to eq 'skipped'
      end
    end

    context 'when stage is scheduled because of scheduled builds' do
      before do
        create(:ci_build, :scheduled, stage_id: stage.id)
      end

      it 'updates status to scheduled' do
        expect { stage.update_legacy_status }
          .to change { stage.reload.status }
          .to 'scheduled'
      end
    end

    context 'when build is waiting for resource' do
      before do
        create(:ci_build, :waiting_for_resource, stage_id: stage.id)
      end

      it 'updates status to waiting for resource' do
        expect { stage.update_legacy_status }
          .to change { stage.reload.status }
          .to 'waiting_for_resource'
      end
    end

    context 'when stage is skipped because is empty' do
      it 'updates status to skipped' do
        expect { stage.update_legacy_status }
          .to change { stage.reload.status }
          .to eq('skipped')
      end
    end

    context 'when stage object is locked' do
      before do
        create(:ci_build, :failed, stage_id: stage.id)
      end

      it 'retries a lock to update a stage status' do
        stage.lock_version = 100

        stage.update_legacy_status

        expect(stage.reload).to be_failed
      end
    end

    context 'when statuses status was not recognized' do
      before do
        allow(stage)
          .to receive(:latest_stage_status)
          .and_return(:unknown)
      end

      it 'raises an exception' do
        expect { stage.update_legacy_status }
          .to raise_error(Ci::HasStatus::UnknownStatusError)
      end
    end
  end

  describe '#detailed_status' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { create(:user) }
    let(:stage) { create(:ci_stage_entity, status: :created) }

    subject { stage.detailed_status(user) }

    where(:statuses, :label) do
      %w[created]         | :created
      %w[success]         | :passed
      %w[pending]         | :pending
      %w[skipped]         | :skipped
      %w[canceled]        | :canceled
      %w[success failed]  | :failed
      %w[running pending] | :running
    end

    with_them do
      before do
        statuses.each do |status|
          create(:commit_status, project: stage.project,
                                 pipeline: stage.pipeline,
                                 stage_id: stage.id,
                                 status: status)

          stage.update_legacy_status
        end
      end

      it 'has a correct label' do
        expect(subject.label).to eq(label.to_s)
      end
    end

    context 'when stage has warnings' do
      before do
        create(:ci_build, project: stage.project,
                          pipeline: stage.pipeline,
                          stage_id: stage.id,
                          status: :failed,
                          allow_failure: true)

        stage.update_legacy_status
      end

      it 'is passed with warnings' do
        expect(subject.label).to eq s_('CiStatusLabel|passed with warnings')
      end
    end
  end

  describe '#groups' do
    before do
      create(:ci_build, stage_id: stage.id, name: 'rspec 0 1')
      create(:ci_build, stage_id: stage.id, name: 'rspec 0 2')
    end

    it 'groups stage builds by name' do
      expect(stage.groups).to be_one
      expect(stage.groups.first.name).to eq 'rspec'
    end
  end

  describe '#delay' do
    subject { stage.delay }

    let(:stage) { create(:ci_stage_entity, status: :created) }

    it 'updates stage status' do
      subject

      expect(stage).to be_scheduled
    end
  end

  describe '#position' do
    context 'when stage has been imported and does not have position index set' do
      before do
        stage.update_column(:position, nil)
      end

      context 'when stage has statuses' do
        before do
          create(:ci_build, :running, stage_id: stage.id, stage_idx: 10)
        end

        it 'recalculates index before updating status' do
          expect(stage.reload.position).to be_nil

          stage.update_legacy_status

          expect(stage.reload.position).to eq 10
        end
      end

      context 'when stage has statuses with nil idx' do
        before do
          create(:ci_build, :running, stage_id: stage.id, stage_idx: nil)
          create(:ci_build, :running, stage_id: stage.id, stage_idx: 10)
          create(:ci_build, :running, stage_id: stage.id, stage_idx: nil)
        end

        it 'sets index to a non-empty value' do
          expect { stage.update_legacy_status }.to change { stage.reload.position }.from(nil).to(10)
        end
      end

      context 'when stage does not have statuses' do
        it 'fallbacks to zero' do
          expect(stage.reload.position).to be_nil

          stage.update_legacy_status

          expect(stage.reload.position).to eq 0
        end
      end
    end
  end

  context 'when stage has warnings' do
    before do
      create(:ci_build, :failed, :allowed_to_fail, stage_id: stage.id)
      create(:ci_bridge, :failed, :allowed_to_fail, stage_id: stage.id)
    end

    describe '#has_warnings?' do
      it 'returns true' do
        expect(stage).to have_warnings
      end
    end

    describe '#number_of_warnings' do
      it 'returns a lazy stage warnings counter' do
        lazy_queries = ActiveRecord::QueryRecorder.new do
          stage.number_of_warnings
        end

        synced_queries = ActiveRecord::QueryRecorder.new do
          stage.number_of_warnings.to_i
        end

        expect(lazy_queries.count).to eq 0
        expect(synced_queries.count).to eq 1

        expect(stage.number_of_warnings.inspect).to include 'BatchLoader'
        expect(stage.number_of_warnings).to eq 2
      end
    end
  end

  context 'when stage does not have warnings' do
    describe '#has_warnings?' do
      it 'returns false' do
        expect(stage).not_to have_warnings
      end
    end
  end

  it_behaves_like 'manual playable stage', :ci_stage_entity
end
