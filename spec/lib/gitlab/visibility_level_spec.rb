# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::VisibilityLevel do
  describe '.level_value' do
    it 'converts "public" to integer value' do
      expect(described_class.level_value('public')).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'converts string integer to integer value' do
      expect(described_class.level_value('20')).to eq(20)
    end

    it 'defaults to PRIVATE when string value is not valid' do
      expect(described_class.level_value('invalid')).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'defaults to PRIVATE when integer value is not valid' do
      expect(described_class.level_value(100)).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  describe '.levels_for_user' do
    context 'when admin mode is enabled', :enable_admin_mode do
      it 'returns all levels for an admin' do
        user = build(:user, :admin)

        expect(described_class.levels_for_user(user))
          .to eq([Gitlab::VisibilityLevel::PRIVATE,
                  Gitlab::VisibilityLevel::INTERNAL,
                  Gitlab::VisibilityLevel::PUBLIC])
      end
    end

    context 'when admin mode is disabled' do
      it 'returns INTERNAL and PUBLIC for an admin' do
        user = build(:user, :admin)

        expect(described_class.levels_for_user(user))
            .to eq([Gitlab::VisibilityLevel::INTERNAL,
                    Gitlab::VisibilityLevel::PUBLIC])
      end
    end

    it 'returns INTERNAL and PUBLIC for internal users' do
      user = build(:user)

      expect(described_class.levels_for_user(user))
        .to eq([Gitlab::VisibilityLevel::INTERNAL,
                Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'returns PUBLIC for external users' do
      user = build(:user, :external)

      expect(described_class.levels_for_user(user))
        .to eq([Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'returns PUBLIC when no user is given' do
      expect(described_class.levels_for_user)
        .to eq([Gitlab::VisibilityLevel::PUBLIC])
    end
  end

  describe '.allowed_levels' do
    it 'only includes the levels that arent restricted' do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])

      expect(described_class.allowed_levels)
        .to contain_exactly(described_class::PRIVATE, described_class::PUBLIC)
    end

    it 'returns all levels when no visibility level was set' do
      allow(described_class)
        .to receive_message_chain('current_application_settings.restricted_visibility_levels')
              .and_return(nil)

      expect(described_class.allowed_levels)
        .to contain_exactly(described_class::PRIVATE, described_class::INTERNAL, described_class::PUBLIC)
    end
  end

  describe '.closest_allowed_level' do
    it 'picks INTERNAL instead of PUBLIC if public is restricted' do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])

      expect(described_class.closest_allowed_level(described_class::PUBLIC))
        .to eq(described_class::INTERNAL)
    end

    it 'picks PRIVATE if nothing is available' do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC,
                                                              Gitlab::VisibilityLevel::INTERNAL,
                                                              Gitlab::VisibilityLevel::PRIVATE])

      expect(described_class.closest_allowed_level(described_class::PUBLIC))
        .to eq(described_class::PRIVATE)
    end
  end

  describe '.valid_level?' do
    it 'returns true when visibility is valid' do
      expect(described_class.valid_level?(described_class::PRIVATE)).to be_truthy
      expect(described_class.valid_level?(described_class::INTERNAL)).to be_truthy
      expect(described_class.valid_level?(described_class::PUBLIC)).to be_truthy
    end
  end

  describe '.restricted_level?, .non_restricted_level?, and .public_level_restricted?' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_levels, :expected_status) do
      nil | false
      [Gitlab::VisibilityLevel::PRIVATE] | false
      [Gitlab::VisibilityLevel::PRIVATE, Gitlab::VisibilityLevel::INTERNAL] | false
      [Gitlab::VisibilityLevel::PUBLIC] | true
      [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::INTERNAL] | true
    end

    with_them do
      before do
        stub_application_setting(restricted_visibility_levels: visibility_levels)
      end

      it 'returns the expected status' do
        expect(described_class.restricted_level?(Gitlab::VisibilityLevel::PUBLIC)).to eq(expected_status)
        expect(described_class.non_restricted_level?(Gitlab::VisibilityLevel::PUBLIC)).to eq(!expected_status)
        expect(described_class.public_visibility_restricted?).to eq(expected_status)
      end
    end
  end

  describe '.options' do
    context 'keys' do
      it 'returns the allowed visibility levels' do
        expect(described_class.options.keys).to contain_exactly('Private', 'Internal', 'Public')
      end
    end
  end

  describe '.level_name' do
    using RSpec::Parameterized::TableSyntax

    where(:level_value, :level_name) do
      described_class::PRIVATE | 'Private'
      described_class::INTERNAL | 'Internal'
      described_class::PUBLIC | 'Public'
      non_existing_record_access_level | 'Unknown'
    end

    with_them do
      it 'returns the name of the visibility level' do
        expect(described_class.level_name(level_value)).to eq(level_name)
      end
    end
  end
end
