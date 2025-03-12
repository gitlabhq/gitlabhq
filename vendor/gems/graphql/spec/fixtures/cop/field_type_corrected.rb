class Types::Query
  field :current_account, null: false, description: "The account of the current viewer" do
    type Types::Account
  end

  field :find_account do
    type Types::Account
    argument :id, ID
  end

  # Don't modify these:
  field :current_time, String, description: "The current time in the viewer's timezone"
  field :current_time, Integer, description: "The current time in the viewer's timezone"
  field :current_time, Int, description: "The current time in the viewer's timezone"
  field :current_time, Float, description: "The current time in the viewer's timezone"
  field :current_time, Boolean, description: "The current time in the viewer's timezone"

  field(:all_accounts) {
    type [Types::Account, null: false]
    argument :active, Boolean, default_value: false
  }
end
