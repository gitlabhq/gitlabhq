# frozen_string_literal: true

module StubExperiments
  # Stub Experiment with `key: true/false`
  #
  # @param [Hash] experiment where key is feature name and value is boolean whether active or not.
  #
  # Examples
  # - `stub_experiment(signup_flow: false)` ... Disables `signup_flow` experiment.
  def stub_experiment(experiments)
    allow(Gitlab::Experimentation).to receive(:active?).and_call_original

    experiments.each do |experiment_key, enabled|
      allow(Gitlab::Experimentation).to receive(:active?).with(experiment_key) { enabled }
    end
  end

  # Stub Experiment for user with `key: true/false`
  #
  # @param [Hash] experiment where key is feature name and value is boolean whether enabled or not.
  #
  # Examples
  # - `stub_experiment_for_subject(signup_flow: false)` ... Disable `signup_flow` experiment for user.
  def stub_experiment_for_subject(experiments)
    allow(Gitlab::Experimentation).to receive(:in_experiment_group?).and_call_original

    experiments.each do |experiment_key, enabled|
      allow(Gitlab::Experimentation).to receive(:in_experiment_group?).with(experiment_key, anything) { enabled }
    end
  end

  private

  def feature_flag_suffix
    Gitlab::Experimentation::Experiment::FEATURE_FLAG_SUFFIX
  end
end
