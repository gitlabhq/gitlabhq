# frozen_string_literal: true

# Temporary parity harness for the characteristic-hash scope migration
# (https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/28881).
# It is deleted together with positional scope routing in the final migration commit.
RSpec.shared_examples 'application rate limiter characteristic hash parity' do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:environment) { build_stubbed(:environment, project: project) }
  let_it_be(:pipeline_schedule) { build_stubbed(:ci_pipeline_schedule, project: project) }
  let_it_be(:import_source_user) { build_stubbed(:import_source_user) }
  let_it_be(:deploy_key) { build_stubbed(:deploy_key) }
  let_it_be(:deploy_token) { build_stubbed(:deploy_token) }

  def legacy_ar_characteristic_types
    types = {
      ::User => :user,
      ::Project => :project,
      ::Group => :group,
      ::Namespace => :namespace,
      ::Environment => :environment,
      ::Ci::PipelineSchedule => :ci_pipeline_schedule,
      ::Import::SourceUser => :import_source_user,
      ::Key => :key,
      ::MergeRequest => :merge_request
    }
    types[::Ai::DuoWorkflows::Workflow] = :duo_workflow if Gitlab.ee?
    types
  end

  def legacy_ar_characteristic_for(value, characteristics)
    char = legacy_ar_characteristic_types[value.class]
    return char if char && characteristics.include?(char)

    legacy_ar_characteristic_types.each do |klass, characteristic|
      return characteristic if value.is_a?(klass) && characteristics.include?(characteristic)
    end
    nil
  end

  def legacy_identifier_for(characteristics, scope)
    values = Array(scope).flatten.compact
    identifier = {}
    remaining_values = []

    values.each do |value|
      characteristic = legacy_ar_characteristic_for(value, characteristics)
      if characteristic && !identifier.key?(characteristic)
        identifier[characteristic] = value.id
      else
        remaining_values << value
      end
    end

    ar_names = legacy_ar_characteristic_types.values.to_set
    primitive_characteristics = characteristics.reject do |characteristic|
      ar_names.include?(characteristic) || identifier.key?(characteristic)
    end

    primitive_characteristics.zip(remaining_values).each do |characteristic, value|
      next if value.nil?

      identifier[characteristic] = value.to_s
    end

    identifier
  end

  def hash_identifier_for(characteristics, scope)
    Gitlab::ApplicationRateLimiter::LabkitAdapter.send(:identifier_for, characteristics, scope)
  end

  def characteristics_for(key)
    Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits.rule_for(key).characteristics
  end

  it 'produces identifiers byte-identical to the positional forms', :aggregate_failures do
    rows.each do |key, legacy_scope, hash_scope|
      characteristics = characteristics_for(key)

      expect(hash_identifier_for(characteristics, hash_scope)).to eq(
        legacy_identifier_for(characteristics, legacy_scope)
      ), "identifier mismatch for #{key} (legacy scope: #{legacy_scope.inspect})"
    end
  end
end
