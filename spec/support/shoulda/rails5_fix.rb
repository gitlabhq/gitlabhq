# Remove this file once https://github.com/thoughtbot/shoulda-matchers/issues/913
# released into new version of the shoulda-matchers
module Shoulda
  module Matchers
    RailsShim.class_eval do
      def self.serialized_attributes_for(model)
        if defined?(::ActiveRecord::Type::Serialized)
          # Rails 5+
          model.columns.select do |column|
            model.type_for_attribute(column.name).is_a?(::ActiveRecord::Type::Serialized)
          end.inject({}) do |hash, column|
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
