# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    module Rails
      class Routes
        class Mapper
          def initialize(mapping = Mapping.new)
            @mapping = mapping
          end

          def map(&block)
            instance_eval(&block) if block
            @mapping
          end

          def controllers(controller_names = {})
            @mapping.controllers.merge!(controller_names)
          end

          def skip_controllers(*controller_names)
            @mapping.skips = controller_names
          end

          def as(alias_names = {})
            @mapping.as.merge!(alias_names)
          end
        end
      end
    end
  end
end
