# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Release, feature_category: :organization do
  let(:registry) { instance_double(described_class::Registry) }

  before do
    allow(described_class::Registry).to receive(:instance).and_return(registry)
  end

  def stub_flag(name: :feature, stage: :beta, description: 'An organization flag.')
    flag = described_class::Flag.new(
      name: name.to_s,
      description: description,
      stage: described_class::Stage::BY_KEY.fetch(stage)
    )
    allow(registry).to receive(:find).with(name).and_return(flag)

    flag
  end

  describe '.enabled?' do
    let(:actor) { build_stubbed(:user) }

    # The argument to `enabled?` is an organization flag (such as
    # :ui_for_organizations): the registry key for one feature. The feature's
    # stage decides which org_stage_* stage flags gate it.
    context 'when a feature is registered at a stage' do
      before do
        stub_flag(name: :ui_for_organizations, stage: :beta)
      end

      it 'is enabled when the backing stage flag is on' do
        expect(described_class.enabled?(:ui_for_organizations, actor)).to be(true)
      end

      it 'is disabled when the backing stage flag and every earlier stage flag are off' do
        stub_feature_flags(org_stage_experimental: false, org_stage_beta: false)

        expect(described_class.enabled?(:ui_for_organizations, actor)).to be(false)
      end

      it 'checks the stage flags instance-wide when the actor is nil' do
        expect(described_class.enabled?(:ui_for_organizations, nil)).to be(true)
      end
    end

    describe 'cascading stages' do
      context 'when a feature is at the Experimental stage' do
        before do
          stub_flag(name: :ui_for_organizations, stage: :experimental)
          stub_feature_flags(org_stage_experimental: false)
        end

        it 'stays disabled when only a later stage flag is on' do
          stub_feature_flags(org_stage_beta: true)

          expect(described_class.enabled?(:ui_for_organizations, actor)).to be(false)
        end
      end

      context 'when a feature is at the Beta stage' do
        before do
          stub_flag(name: :ui_for_organizations, stage: :beta)
          stub_feature_flags(org_stage_experimental: false, org_stage_beta: false)
        end

        it 'is enabled when an earlier stage flag is on' do
          stub_feature_flags(org_stage_experimental: true)

          expect(described_class.enabled?(:ui_for_organizations, actor)).to be(true)
        end

        it 'stays disabled when only a later stage flag is on' do
          stub_feature_flags(org_stage_la_25: true, org_stage_ga: true)

          expect(described_class.enabled?(:ui_for_organizations, actor)).to be(false)
        end
      end

      context 'when a feature is at an LA stage' do
        before do
          stub_flag(name: :ui_for_organizations, stage: :la_50)
          stub_feature_flags(org_stage_experimental: false, org_stage_beta: false, org_stage_la_50: false)
        end

        it 'is enabled when an earlier cascading stage flag is on' do
          stub_feature_flags(org_stage_beta: true)

          expect(described_class.enabled?(:ui_for_organizations, actor)).to be(true)
        end

        it 'stays disabled when only another LA stage flag is on' do
          stub_feature_flags(org_stage_la_25: true)

          expect(described_class.enabled?(:ui_for_organizations, actor)).to be(false)
        end
      end

      context 'when a feature is at the GA stage' do
        before do
          stub_flag(name: :ui_for_organizations, stage: :ga)
        end

        it 'checks only the GA stage flag and ignores earlier stages' do
          stub_feature_flags(org_stage_ga: false, org_stage_experimental: true, org_stage_beta: true)

          expect(described_class.enabled?(:ui_for_organizations, actor)).to be(false)
        end
      end
    end

    context 'when the organization flag is unknown' do
      before do
        allow(registry).to receive(:find).with(:nope)
          .and_raise(described_class::UnknownFlagError)
      end

      it 'raises' do
        expect { described_class.enabled?(:nope, actor) }
          .to raise_error(described_class::UnknownFlagError)
      end
    end
  end

  describe '.stages' do
    it 'returns every stage in progression order' do
      expect(described_class.stages.map(&:key))
        .to eq(%i[experimental beta la_25 la_50 la_75 la_100 ga])
    end

    # `enabled?` builds each stage flag inline as `:"org_stage_#{key}"`, and the
    # feature-flag usage scanner only tracks them while every stage flag follows
    # that name. This test guards the convention.
    it 'names every flag org_stage_<key>', :aggregate_failures do
      described_class.stages.each do |stage|
        expect(stage.flag).to eq(:"org_stage_#{stage.key}")
      end
    end
  end
end
