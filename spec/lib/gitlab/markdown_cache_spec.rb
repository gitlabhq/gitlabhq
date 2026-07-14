# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MarkdownCache, feature_category: :markdown do
  using RSpec::Parameterized::TableSyntax

  let(:rollout_flag) { :"markdown_cache_stochastic_rollout_#{described_class::CACHE_COMMONMARK_VERSION}" }
  let(:current_shifted) { described_class::CACHE_COMMONMARK_VERSION_SHIFTED }
  let(:previous_shifted) { (described_class::CACHE_COMMONMARK_VERSION - 1) << 16 }
  let(:older_shifted) { (described_class::CACHE_COMMONMARK_VERSION - 2) << 16 }

  # The application-setting local version is constant across every example; the
  # `local_version` argument either overrides it (when non-nil) or falls back to
  # it. Examples combine the shifted base with `local_version || 2` to build the
  # expected full version.
  before do
    stub_application_setting(local_markdown_version: 2)
  end

  # Puts the module into steady state (no rollout) or mid-rollout by stubbing the
  # previous shifted version, and optionally sets the stochastic rollout flag.
  def configure_rollout(rollout_active:, flag: nil)
    previous = rollout_active ? previous_shifted : nil
    stub_const("#{described_class}::CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED", previous)
    stub_feature_flags(rollout_flag => flag) unless flag.nil?
  end

  describe '.latest_cached_markdown_version' do
    # A read rolls to the previous version only mid-rollout with the flag off;
    # otherwise it treats the current version as latest. `:expected` names which
    # shifted base to OR the effective local version into.
    where(:rollout_active, :flag, :local_version, :expected) do
      false | false | nil | :current
      false | true  | nil | :current
      false | false | 5   | :current
      true  | false | nil | :previous
      true  | false | 5   | :previous
      true  | true  | nil | :current
      true  | true  | 5   | :current
    end

    with_them do
      it 'returns the expected shifted version OR-ed with the local version' do
        configure_rollout(rollout_active: rollout_active, flag: flag)

        # NB: shifted bases have empty low bits, so `+` matches the `|` the code
        # uses. We avoid `|` here because TableSyntax overrides it to build table
        # rows, even inside example bodies (!).
        expected_base = expected == :current ? current_shifted : previous_shifted

        expect(described_class.latest_cached_markdown_version(local_version: local_version))
          .to eq(expected_base + (local_version || 2))
      end
    end
  end

  describe '.cached_markdown_version_for_write' do
    # Writes always target the current version, regardless of rollout or flag.
    where(:rollout_active, :flag, :local_version) do
      false | false | nil
      false | false | 5
      true  | false | nil
      true  | true  | nil
      true  | true  | 5
    end

    with_them do
      it 'returns the current shifted version OR-ed with the local version' do
        configure_rollout(rollout_active: rollout_active, flag: flag)

        expect(described_class.cached_markdown_version_for_write(local_version: local_version))
          .to eq(current_shifted + (local_version || 2))
      end
    end
  end

  describe '.previous_cached_markdown_version' do
    # Only meaningful mid-rollout; nil in steady state as there is no previous.
    where(:rollout_active, :local_version, :expected_previous) do
      false | nil | false
      false | 5   | false
      true  | nil | true
      true  | 5   | true
    end

    with_them do
      it 'returns the previous shifted version OR-ed with the local version, or nil' do
        configure_rollout(rollout_active: rollout_active)

        expected_value = expected_previous ? previous_shifted + (local_version || 2) : nil

        expect(described_class.previous_cached_markdown_version(local_version: local_version))
          .to eq(expected_value)
      end
    end
  end

  describe '.upgrade_kind' do
    # A row at the previous version is the rollout's target; anything older or
    # versionless is a backfill. With no rollout active, everything is backfill.
    # `:persisted` names the row's load-time version (`nil` for versionless).
    where(:rollout_active, :persisted, :expected_kind) do
      false | nil        | :backfill
      false | :previous  | :backfill
      true  | nil        | :backfill
      true  | :previous  | :rollout
      true  | :older     | :backfill
    end

    with_them do
      it 'classifies the upgrade by the load-time persisted version' do
        configure_rollout(rollout_active: rollout_active)

        # A persisted row carries the local bits too.
        persisted_version =
          case persisted
          when :previous then previous_shifted + 2
          when :older then older_shifted + 2
          end

        expect(described_class.upgrade_kind(persisted_version, local_version: nil)).to eq(expected_kind)
      end
    end
  end
end
