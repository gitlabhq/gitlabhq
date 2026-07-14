# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ReleaseHelpers, feature_category: :organization do
  def register(name, stage: :beta)
    flag = ::Organizations::Release::Flag.new(
      name: name.to_s,
      description: 'For specs',
      stage: ::Organizations::Release::Stage::BY_KEY.fetch(stage)
    )
    allow(::Organizations::Release::Registry.instance).to receive(:find).with(name).and_return(flag)
  end

  describe '#stub_organization_release' do
    before do
      register(:demo_flag)
    end

    it 'pins a feature enabled' do
      stub_organization_release(demo_flag: true)

      expect(::Organizations::Release.enabled?(:demo_flag, nil)).to be(true)
    end

    it 'pins a feature disabled' do
      stub_organization_release(demo_flag: false)

      expect(::Organizations::Release.enabled?(:demo_flag, nil)).to be(false)
    end

    it 'pins regardless of the actor' do
      stub_organization_release(demo_flag: false)

      expect(::Organizations::Release.enabled?(:demo_flag, build_stubbed(:user))).to be(false)
    end

    it 'pins features independently, even at the same stage' do
      register(:other_flag) # also Beta, so it shares demo_flag's stage flag

      stub_organization_release(demo_flag: false)

      expect(::Organizations::Release.enabled?(:demo_flag, nil)).to be(false)
      expect(::Organizations::Release.enabled?(:other_flag, nil)).to be(true)
    end

    it 'accumulates across calls' do
      register(:other_flag)

      stub_organization_release(demo_flag: false)
      stub_organization_release(other_flag: false)

      expect(::Organizations::Release.enabled?(:demo_flag, nil)).to be(false)
      expect(::Organizations::Release.enabled?(:other_flag, nil)).to be(false)
    end

    it 'raises for an unknown flag' do
      allow(::Organizations::Release::Registry.instance)
        .to receive(:find).with(:unknown_flag).and_call_original

      expect { stub_organization_release(unknown_flag: true) }
        .to raise_error(::Organizations::Release::UnknownFlagError)
    end
  end
end
