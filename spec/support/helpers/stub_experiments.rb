# frozen_string_literal: true

module StubExperiments
  # Stub Experiment with `key: true/false`
  #
  # @param [Hash] experiment where key is feature name and value is boolean whether enabled or not.
  #
  # Examples
  # - `stub_experiment(signup_flow: false)` ... Disable `signup_flow` experiment globally.
  def stub_experiment(experiments)
    experiments.each do |experiment_key, enabled|
      allow(Gitlab::Experimentation).to receive(:enabled?).with(experiment_key, any_args) { enabled }
    end
  end
end
