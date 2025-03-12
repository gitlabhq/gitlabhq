# frozen_string_literal: true

ActiveSupport.on_load(:graphql_dashboard_application_controller) do
  def self.hook_was_called?
    true
  end
end
