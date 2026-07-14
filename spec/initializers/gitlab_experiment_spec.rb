# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitlab::Experiment configuration', feature_category: :acquisition do
  describe 'secure_cookie setting' do
    it 'sets secure_cookie based on gitlab https config in test to false' do
      expect(Gitlab::Experiment::Configuration.secure_cookie).to be(false)
    end

    it 'follows a change to true for the gitlab https config' do
      stub_config_setting(https: true)

      load_initializer

      expect(Gitlab::Experiment::Configuration.secure_cookie).to be(true)
    end
  end

  describe 'strict_registration setting' do
    it 'enables strict registration' do
      expect(Gitlab::Experiment::Configuration.strict_registration).to be(true)
    end

    it 'raises an error when running an anonymous experiment without a registered class' do
      dsl = Class.new { include Gitlab::Experiment::Dsl }.new

      expect { dsl.experiment(:this_experiment_is_not_registered) }
        .to raise_error(Gitlab::Experiment::UnregisteredExperiment)
    end
  end

  def load_initializer
    load Rails.root.join('config/initializers/gitlab_experiment.rb')
  end
end
