require 'delegate'
module Kubeclient
  module Common
    # Kubernetes Entity List
    class EntityList < DelegateClass(Array)
      attr_reader :continue, :kind, :resourceVersion

      def initialize(kind, resource_version, list, continue = nil)
        @kind = kind
        # rubocop:disable Style/VariableName
        @resourceVersion = resource_version
        @continue = continue
        super(list)
      end

      def last?
        continue.nil?
      end
    end
  end
end
