# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Processable do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  describe 'delegations' do
    subject { Ci::Processable.new }

    it { is_expected.to delegate_method(:merge_request?).to(:pipeline) }
    it { is_expected.to delegate_method(:merge_request_ref?).to(:pipeline) }
    it { is_expected.to delegate_method(:legacy_detached_merge_request_pipeline?).to(:pipeline) }
  end

  describe '#aggregated_needs_names' do
    let(:with_aggregated_needs) { pipeline.processables.select_with_aggregated_needs(project) }

    context 'with created status' do
      let!(:processable) { create(:ci_build, :created, project: project, pipeline: pipeline) }

      context 'with needs' do
        before do
          create(:ci_build_need, build: processable, name: 'test1')
          create(:ci_build_need, build: processable, name: 'test2')
        end

        it 'returns all processables' do
          expect(with_aggregated_needs).to contain_exactly(processable)
        end

        it 'returns all needs' do
          expect(with_aggregated_needs.first.aggregated_needs_names).to contain_exactly('test1', 'test2')
        end
      end

      context 'without needs' do
        it 'returns all processables' do
          expect(with_aggregated_needs).to contain_exactly(processable)
        end

        it 'returns empty needs' do
          expect(with_aggregated_needs.first.aggregated_needs_names).to be_nil
        end
      end
    end
  end

  describe 'validate presence of scheduling_type' do
    using RSpec::Parameterized::TableSyntax

    subject { build(:ci_build, project: project, pipeline: pipeline, importing: importing) }

    where(:importing, :should_validate) do
      false | true
      true  | false
    end

    with_them do
      context 'on create' do
        it 'validates presence' do
          if should_validate
            is_expected.to validate_presence_of(:scheduling_type).on(:create)
          else
            is_expected.not_to validate_presence_of(:scheduling_type).on(:create)
          end
        end
      end

      context 'on update' do
        it { is_expected.not_to validate_presence_of(:scheduling_type).on(:update) }
      end
    end
  end

  describe '.populate_scheduling_type!' do
    let!(:build_without_needs) { create(:ci_build, project: project, pipeline: pipeline) }
    let!(:build_with_needs) { create(:ci_build, project: project, pipeline: pipeline) }
    let!(:needs_relation) { create(:ci_build_need, build: build_with_needs) }
    let!(:another_build) { create(:ci_build, project: project) }

    before do
      Ci::Processable.update_all(scheduling_type: nil)
    end

    it 'populates scheduling_type of processables' do
      expect do
        pipeline.processables.populate_scheduling_type!
      end.to change(pipeline.processables.where(scheduling_type: nil), :count).from(2).to(0)

      expect(build_without_needs.reload.scheduling_type).to eq('stage')
      expect(build_with_needs.reload.scheduling_type).to eq('dag')
    end

    it 'does not affect processables from other pipelines' do
      pipeline.processables.populate_scheduling_type!
      expect(another_build.reload.scheduling_type).to be_nil
    end
  end

  describe '#needs_attributes' do
    let(:build) { create(:ci_build, :created, project: project, pipeline: pipeline) }

    subject { build.needs_attributes }

    context 'with needs' do
      before do
        create(:ci_build_need, build: build, name: 'test1')
        create(:ci_build_need, build: build, name: 'test2')
      end

      it 'returns all needs attributes' do
        is_expected.to contain_exactly(
          { 'artifacts' => true, 'name' => 'test1', 'optional' => false },
          { 'artifacts' => true, 'name' => 'test2', 'optional' => false }
        )
      end
    end

    context 'without needs' do
      it { is_expected.to be_empty }
    end
  end

  describe 'state transition with resource group' do
    let(:resource_group) { create(:ci_resource_group, project: project) }

    context 'when build status is created' do
      let(:build) { create(:ci_build, :created, project: project, resource_group: resource_group) }

      it 'is waiting for resource when build is enqueued' do
        expect(Ci::ResourceGroups::AssignResourceFromResourceGroupWorker).to receive(:perform_async).with(resource_group.id)

        expect { build.enqueue! }.to change { build.status }.from('created').to('waiting_for_resource')

        expect(build.waiting_for_resource_at).not_to be_nil
      end

      context 'when build is waiting for resource' do
        before do
          build.update_column(:status, 'waiting_for_resource')
        end

        it 'is enqueued when build requests resource' do
          expect { build.enqueue_waiting_for_resource! }.to change { build.status }.from('waiting_for_resource').to('pending')
        end

        it 'releases a resource when build finished' do
          expect(build.resource_group).to receive(:release_resource_from).with(build).and_call_original
          expect(Ci::ResourceGroups::AssignResourceFromResourceGroupWorker).to receive(:perform_async).with(build.resource_group_id)

          build.enqueue_waiting_for_resource!
          build.success!
        end

        context 'when build has prerequisites' do
          before do
            allow(build).to receive(:any_unmet_prerequisites?) { true }
          end

          it 'is preparing when build is enqueued' do
            expect { build.enqueue_waiting_for_resource! }.to change { build.status }.from('waiting_for_resource').to('preparing')
          end
        end

        context 'when there are no available resources' do
          before do
            resource_group.assign_resource_to(create(:ci_build))
          end

          it 'stays as waiting for resource when build requests resource' do
            expect { build.enqueue_waiting_for_resource }.not_to change { build.status }
          end
        end
      end
    end
  end
end
