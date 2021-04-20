# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Seed::Stage do
  let(:project) { create(:project, :repository) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:previous_stages) { [] }
  let(:seed_context) { double(pipeline: pipeline, root_variables: []) }

  let(:attributes) do
    { name: 'test',
      index: 0,
      builds: [{ name: 'rspec', scheduling_type: :stage },
               { name: 'spinach', scheduling_type: :stage },
               { name: 'deploy', only: { refs: ['feature'] } }], scheduling_type: :stage }
  end

  subject do
    described_class.new(seed_context, attributes, previous_stages)
  end

  describe '#size' do
    it 'returns a number of jobs in the stage' do
      expect(subject.size).to eq 2
    end
  end

  describe '#attributes' do
    it 'returns hash attributes of a stage' do
      expect(subject.attributes).to be_a Hash
      expect(subject.attributes)
        .to include(:name, :position, :pipeline, :project)
    end
  end

  describe '#included?' do
    context 'when it contains builds seeds' do
      let(:attributes) do
        { name: 'test',
          index: 0,
          builds: [{ name: 'deploy', only: { refs: ['master'] } }] }
      end

      it { is_expected.to be_included }
    end

    context 'when it does not contain build seeds' do
      let(:attributes) do
        { name: 'test',
          index: 0,
          builds: [{ name: 'deploy', only: { refs: ['feature'] } }] }
      end

      it { is_expected.not_to be_included }
    end
  end

  describe '#seeds' do
    it 'returns build seeds' do
      expect(subject.seeds).to all(be_a Gitlab::Ci::Pipeline::Seed::Build)
    end

    it 'returns build seeds including valid attributes' do
      expect(subject.seeds.size).to eq 2
      expect(subject.seeds.map(&:attributes)).to all(include(ref: 'master'))
      expect(subject.seeds.map(&:attributes)).to all(include(tag: false))
      expect(subject.seeds.map(&:attributes)).to all(include(project: pipeline.project))
    end

    context 'when a legacy trigger exists' do
      before do
        create(:ci_trigger_request, pipeline: pipeline)
      end

      it 'returns build seeds including legacy trigger' do
        expect(pipeline.legacy_trigger).not_to be_nil
        expect(subject.seeds.map(&:attributes))
          .to all(include(trigger_request: pipeline.legacy_trigger))
      end
    end

    context 'when a ref is protected' do
      before do
        allow_next_instance_of(Project) do |instance|
          allow(instance).to receive(:protected_for?).and_return(true)
        end
      end

      it 'returns protected builds' do
        expect(subject.seeds.map(&:attributes)).to all(include(protected: true))
      end
    end

    context 'when a ref is not protected' do
      before do
        allow_next_instance_of(Project) do |instance|
          allow(instance).to receive(:protected_for?).and_return(false)
        end
      end

      it 'returns unprotected builds' do
        expect(subject.seeds.map(&:attributes)).to all(include(protected: false))
      end
    end

    it 'filters seeds using only/except policies' do
      expect(subject.seeds.map(&:attributes)).to satisfy do |seeds|
        seeds.any? { |hash| hash.fetch(:name) == 'rspec' }
      end

      expect(subject.seeds.map(&:attributes)).not_to satisfy do |seeds|
        seeds.any? { |hash| hash.fetch(:name) == 'deploy' }
      end
    end
  end

  describe '#seeds_names' do
    it 'returns all job names' do
      expect(subject.seeds_names).to contain_exactly(
        'rspec', 'spinach')
    end

    it 'returns a set' do
      expect(subject.seeds_names).to be_a(Set)
    end
  end

  describe '#seeds_errors' do
    it 'returns all errors from seeds' do
      expect(subject.seeds.first)
        .to receive(:errors) { ["build error"] }

      expect(subject.errors).to contain_exactly(
        "build error")
    end
  end

  describe '#to_resource' do
    it 'builds a valid stage object with all builds' do
      subject.to_resource.save!

      expect(pipeline.reload.stages.count).to eq 1
      expect(pipeline.reload.builds.count).to eq 2
      expect(pipeline.builds).to all(satisfy { |job| job.stage_id.present? })
      expect(pipeline.builds).to all(satisfy { |job| job.pipeline.present? })
      expect(pipeline.builds).to all(satisfy { |job| job.project.present? })
      expect(pipeline.stages)
        .to all(satisfy { |stage| stage.pipeline.present? })
      expect(pipeline.stages)
        .to all(satisfy { |stage| stage.project.present? })
    end

    it 'can not be persisted without explicit pipeline assignment' do
      stage = subject.to_resource

      pipeline.save!

      expect(stage).not_to be_persisted
      expect(pipeline.reload.stages.count).to eq 0
      expect(pipeline.reload.builds.count).to eq 0
    end
  end
end
