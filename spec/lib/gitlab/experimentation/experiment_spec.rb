# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Experimentation::Experiment do
  using RSpec::Parameterized::TableSyntax

  let(:percentage) { 50 }
  let(:params) do
    {
      tracking_category: 'Category1',
      use_backwards_compatible_subject_index: true,
      rollout_strategy: nil
    }
  end

  before do
    skip_feature_flags_yaml_validation
    skip_default_enabled_yaml_check
    feature = double('FeatureFlag', percentage_of_time_value: percentage, enabled?: true)
    allow(Feature).to receive(:get).with(:experiment_key_experiment_percentage).and_return(feature)
  end

  subject(:experiment) { described_class.new(:experiment_key, **params) }

  describe '#active?' do
    before do
      allow(Gitlab).to receive(:dev_env_or_com?).and_return(on_gitlab_com)
    end

    subject { experiment.active? }

    where(:on_gitlab_com, :percentage, :is_active) do
      true  | 0  | false
      true  | 10 | true
      false | 0  | false
      false | 10 | false
    end

    with_them do
      it { is_expected.to eq(is_active) }
    end
  end

  describe '#enabled_for_index?' do
    subject { experiment.enabled_for_index?(index) }

    where(:index, :percentage, :is_enabled) do
      50  | 40 | false
      40  | 50 | true
      nil | 50 | false
    end

    with_them do
      it { is_expected.to eq(is_enabled) }
    end
  end
end
