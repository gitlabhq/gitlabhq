# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'overridden has_many :through associations', :eager_load, feature_category: :database do
  let!(:allowed_overrides) do
    [
      # https://gitlab.com/gitlab-org/gitlab/-/issues/424851
      override_class.new(:assignees, 'app/models/concerns/deprecated_assignee.rb'),
      # https://gitlab.com/gitlab-org/gitlab/-/issues/424852
      override_class.new(:authorized_projects, 'app/models/user.rb'),
      # https://gitlab.com/gitlab-org/gitlab/-/issues/424853
      override_class.new(:project, 'app/models/incident_management/issuable_escalation_status.rb'),
      # https://gitlab.com/gitlab-org/gitlab/-/issues/424854
      override_class.new(:remediations, 'ee/app/models/vulnerabilities/finding.rb'),
      # https://gitlab.com/gitlab-org/gitlab/-/issues/450797
      override_class.new(:vulnerability_findings, 'ee/app/models/ee/ci/pipeline.rb')
    ]
  end

  let!(:override_class) do
    Struct.new(:method_name, :file_path, :association_class) do
      def initialize(method_name, file_path, association_class = nil)
        super(method_name, file_path, association_class)
      end

      def ==(other)
        full_source_path, short_path =
          file_path.length > other.file_path.length ? [file_path, other.file_path] : [other.file_path, file_path]
        method_name == other.method_name && full_source_path.include?(short_path)
      end

      def association_type_name
        if association_class == ActiveRecord::Associations::HasOneThroughAssociation
          'has_one through:'
        else
          'has_many through:'
        end
      end
    end
  end

  let!(:documentation_link) do
    'https://docs.gitlab.com/ee/development/gotchas.html#do-not-override-has_many-through-or-has_one-through-associations'
  end

  it 'onlies have allowed list of overridden has_many/has_one :through associations', :aggregate_failures do
    overridden_associations.each do |overriden_method|
      expect(allowed_override?(overriden_method)).to be_truthy,
        "Found an overridden #{overriden_method.association_type_name} association " \
        "named `#{overriden_method.method_name}`, in #{overriden_method.file_path}, which isn't allowed. " \
        "Overriding such associations can have dangerous impacts, see: #{documentation_link}"
    end
  end

  private

  def allowed_override?(overriden_method)
    allowed_overrides.find do |override|
      override == overriden_method
    end
  end

  def overridden_associations
    ApplicationRecord.descendants.reject(&:abstract_class?).each_with_object([]) do |klass, array|
      through_reflections = klass.reflect_on_all_associations.select do |assoc|
        assoc.is_a?(ActiveRecord::Reflection::ThroughReflection)
      end

      overridden_methods = through_reflections
        .map { |association| [association.association_class, association.name] }
        .map { |association_class, method_name| [method_name, source_location(klass, method_name), association_class] }
        .reject { |_, source_location, _| source_location.include?('activerecord-') }

      array << override_class.new(*overridden_methods.flatten) if overridden_methods.any?
    end
  end

  def source_location(klass, method_name)
    klass.instance_method(method_name).source_location.first
  end
end
