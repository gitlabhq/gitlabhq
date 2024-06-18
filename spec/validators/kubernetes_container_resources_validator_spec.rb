# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KubernetesContainerResourcesValidator, feature_category: :shared do
  let(:model) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :resources
      alias_method :resources_before_type_cast, :resources

      validates :resources, kubernetes_container_resources: true
    end.new
  end

  using RSpec::Parameterized::TableSyntax

  where(:resources, :validity, :errors) do
    # rubocop:disable Layout/LineLength -- The RSpec table syntax often requires long lines for errors
    nil                               | false | { resources: ["must be a hash"] }
    ''                                | false | { resources: ["must be a hash"] }
    {}                                | false | { resources: ["must be a hash containing 'cpu' and 'memory' attribute of type string"] }
    { cpu: nil, memory: nil }         | false | { resources: ["'cpu: ' must be a string", "'memory: ' must be a string"] }
    { cpu: "123di", memory: "123oi" } | false | { resources: ["'cpu: 123di' must match the regex '^(\\d+m|\\d+(\\.\\d*)?)$'", "'memory: 123oi' must match the regex '^\\d+(\\.\\d*)?([EPTGMK]|[EPTGMK]i)?$'"] }
    { cpu: "123di", memory: "123oi" } | false | { resources: ["'cpu: 123di' must match the regex '^(\\d+m|\\d+(\\.\\d*)?)$'", "'memory: 123oi' must match the regex '^\\d+(\\.\\d*)?([EPTGMK]|[EPTGMK]i)?$'"] }
    { cpu: "100m", memory: "123Mi" }  | true  | {}
    # rubocop:enable Layout/LineLength
  end

  with_them do
    before do
      model.resources = resources
      model.validate
    end

    it { expect(model.valid?).to eq(validity) }
    it { expect(model.errors.messages).to eq(errors) }
  end
end
