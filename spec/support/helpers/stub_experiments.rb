# frozen_string_literal: true

module StubExperiments
  # Stub Experiment with `key: true/false`
  #
  # @param [Hash] experiment where key is feature name and value is boolean whether enabled or not.
  #
  # Examples
  # - `stub_experiment(signup_flow: false)` ... Disable `signup_flow` experiment globally.
  def stub_experiment(experiments)
    allow(Gitlab::Experimentation).to receive(:enabled?).and_call_original

    experiments.each do |experiment_key, enabled|
      allow(Gitlab::Experimentation).to receive(:enabled?).with(experiment_key) { enabled }
    end
  end

  # Stub Experiment for user with `key: true/false`
  #
  # @param [Hash] experiment where key is feature name and value is boolean whether enabled or not.
  #
  # Examples
  # - `stub_experiment_for_user(signup_flow: false)` ... Disable `signup_flow` experiment for user.
  def stub_experiment_for_user(experiments)
    allow(Gitlab::Experimentation).to receive(:enabled_for_value?).and_call_original

    experiments.each do |experiment_key, enabled|
      allow(Gitlab::Experimentation).to receive(:enabled_for_value?).with(experiment_key, anything) { enabled }
    end
  end
end
