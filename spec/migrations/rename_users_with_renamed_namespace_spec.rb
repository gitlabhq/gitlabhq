require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170518200835_rename_users_with_renamed_namespace.rb')

describe RenameUsersWithRenamedNamespace, :delete do
  it 'renames a user that had their namespace renamed to the namespace path' do
    other_user = create(:user, username: 'kodingu') # rubocop:disable RSpec/FactoriesInMigrationSpecs
    other_user1 = create(:user, username: 'api0') # rubocop:disable RSpec/FactoriesInMigrationSpecs

    user = create(:user, username: "Users0") # rubocop:disable RSpec/FactoriesInMigrationSpecs
    user.update_column(:username, 'Users')
    user1 = create(:user, username: "import0") # rubocop:disable RSpec/FactoriesInMigrationSpecs
    user1.update_column(:username, 'import')

    described_class.new.up

    expect(user.reload.username).to eq('Users0')
    expect(user1.reload.username).to eq('import0')

    expect(other_user.reload.username).to eq('kodingu')
    expect(other_user1.reload.username).to eq('api0')
  end
end
