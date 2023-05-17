# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::RunnerBackoff::MigrationHelpers, feature_category: :database do
  let(:class_def) do
    Class.new.prepend(described_class)
  end

  describe '.enable_runner_backoff!' do
    it 'sets the flag' do
      expect { class_def.enable_runner_backoff! }
        .to change { class_def.enable_runner_backoff? }
        .from(false).to(true)
    end
  end

  describe '.enable_runner_backoff?' do
    subject { class_def.enable_runner_backoff? }

    it { is_expected.to be_falsy }

    it 'returns true if the flag is set' do
      class_def.enable_runner_backoff!

      is_expected.to be_truthy
    end
  end

  describe '#enable_runner_backoff?' do
    subject { class_def.new.enable_runner_backoff? }

    it { is_expected.to be_falsy }

    it 'returns true if the flag is set' do
      class_def.enable_runner_backoff!

      is_expected.to be_truthy
    end
  end
end
