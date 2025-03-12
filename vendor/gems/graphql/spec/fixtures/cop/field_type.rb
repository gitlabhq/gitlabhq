class Types::Query
  field :current_account, Types::Account, null: false, description: "The account of the current viewer"

  field :find_account, Types::Account do
    argument :id, ID
  end

  # Don't modify these:
  field :current_time, String, description: "The current time in the viewer's timezone"
  field :current_time, Integer, description: "The current time in the viewer's timezone"
  field :current_time, Int, description: "The current time in the viewer's timezone"
  field :current_time, Float, description: "The current time in the viewer's timezone"
  field :current_time, Boolean, description: "The current time in the viewer's timezone"

  field(:all_accounts, [Types::Account, null: false]) {
    argument :active, Boolean, default_value: false
  }
end
