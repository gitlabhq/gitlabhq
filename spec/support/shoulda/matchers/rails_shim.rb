# monkey patch which fixes serialization matcher in Rails 5
# https://github.com/thoughtbot/shoulda-matchers/issues/913
# This can be removed when a new version of shoulda-matchers
# is released
module Shoulda
  module Matchers
    class RailsShim
      def self.serialized_attributes_for(model)
        if defined?(::ActiveRecord::Type::Serialized)
          # Rails 5+
          serialized_columns = model.columns.select do |column|
            model.type_for_attribute(column.name).is_a?(
              ::ActiveRecord::Type::Serialized
            )
          end

          serialized_columns.inject({}) do |hash, column| # rubocop:disable Style/EachWithObject
            hash[column.name.to_s] = model.type_for_attribute(column.name).coder
            hash
          end
        else
          model.serialized_attributes
        end
      end
    end
  end
end
