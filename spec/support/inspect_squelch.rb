# frozen_string_literal: true

# This class can generate a lot of output if it fails,
# so squelch the instance variable output.
class ActiveSupport::Cache::NullStore
  def inspect
    "<#{self.class}>"
  end
end
