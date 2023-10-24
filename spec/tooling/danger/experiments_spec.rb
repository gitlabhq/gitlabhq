# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/experiments'

RSpec.describe Tooling::Danger::Experiments, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

  subject(:experiments) { fake_danger.new(helper: fake_helper) }

  describe '#removed_experiments' do
    let(:removed_experiments_yml_files) do
      [
        'config/feature_flags/experiment/tier_badge.yml',
        'ee/config/feature_flags/experiment/direct_to_trial.yml'
      ]
    end

    let(:deleted_files) do
      [
        'app/models/model.rb',
        'app/assets/javascripts/file.js'
      ] + removed_experiments_yml_files
    end

    it 'returns names of removed experiments' do
      expect(experiments.removed_experiments).to eq(%w[tier_badge direct_to_trial])
    end
  end

  describe '#class_files_removed?' do
    let(:removed_experiments_name) { current_experiment_with_class_files_example }

    context 'when yml file is deleted but not class file' do
      let(:deleted_files) { ["config/feature_flags/experiment/#{removed_experiments_name}.yml"] }

      it 'returns false' do
        expect(experiments.class_files_removed?).to eq(false)
      end
    end

    context 'when yml file is deleted but no corresponding class file exists' do
      let(:deleted_files) { ["config/feature_flags/experiment/fake_experiment.yml"] }

      it 'returns true' do
        expect(experiments.class_files_removed?).to eq(true)
      end
    end
  end

  def current_experiment_with_class_files_example
    path = Dir.glob("app/experiments/*.rb").last
    File.basename(path).chomp('_experiment.rb')
  end
end
