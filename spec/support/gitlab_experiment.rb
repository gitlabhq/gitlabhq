# frozen_string_literal: true

# This is a temporary fix until we have a larger discussion around the
# challenges raised in https://gitlab.com/gitlab-org/gitlab/-/issues/300104
class ApplicationExperiment < Gitlab::Experiment # rubocop:disable Gitlab/NamespacedClass
  def initialize(*args)
    super
    Feature.persist_used!(name)
  end
end

# Disable all caching for experiments in tests.
Gitlab::Experiment::Configuration.cache = nil
