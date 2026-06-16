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
    context 'when the flag is at a gated stage' do
      before do
        stub_flag(name: :ui_for_organizations, stage: :beta)
      end

      it 'is true when the stage flag is enabled' do
        expect(described_class.enabled?(:ui_for_organizations, build_stubbed(:user))).to be(true)
      end

      context 'when the stage flag is disabled' do
        before do
          stub_feature_flags(org_stage_beta: false)
        end

        it 'is false' do
          expect(described_class.enabled?(:ui_for_organizations, build_stubbed(:user))).to be(false)
        end
      end
    end

    context 'when the actor is nil' do
      before do
        stub_flag(name: :ui_for_organizations, stage: :beta)
      end

      it 'checks the stage flag instance-wide gate' do
        expect(described_class.enabled?(:ui_for_organizations, nil)).to be(true)
      end
    end

    context 'when the flag is unknown' do
      before do
        allow(registry).to receive(:find).with(:nope)
          .and_raise(described_class::UnknownFlagError)
      end

      it 'raises' do
        expect { described_class.enabled?(:nope, build_stubbed(:user)) }
          .to raise_error(described_class::UnknownFlagError)
      end
    end
  end

  describe '.stages' do
    it 'returns every stage in progression order' do
      expect(described_class.stages.map(&:key))
        .to eq(%i[experimental beta la_25 la_50 la_75 la_100 ga])
    end

    # `.enabled?` builds the flag inline as `:"org_stage_#{stage.key}"` so the
    # feature-flag usage check can track the family. That is only correct while
    # every stage's flag matches that convention.
    it 'names every flag org_stage_<key>', :aggregate_failures do
      described_class.stages.each do |stage|
        expect(stage.flag).to eq(:"org_stage_#{stage.key}")
      end
    end
  end
end
