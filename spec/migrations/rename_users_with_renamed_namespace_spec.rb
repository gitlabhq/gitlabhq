require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170518200835_rename_users_with_renamed_namespace.rb')

describe RenameUsersWithRenamedNamespace, :delete do
  it 'renames a user that had their namespace renamed to the namespace path' do
    other_user = create(:user, username: 'kodingu')
    other_user1 = create(:user, username: 'api0')

    user = create(:user, username: "Users0")
    user.update_attribute(:username, 'Users')
    user1 = create(:user, username: "import0")
    user1.update_attribute(:username, 'import')

    described_class.new.up

    expect(user.reload.username).to eq('Users0')
    expect(user1.reload.username).to eq('import0')

    expect(other_user.reload.username).to eq('kodingu')
    expect(other_user1.reload.username).to eq('api0')
  end
end
