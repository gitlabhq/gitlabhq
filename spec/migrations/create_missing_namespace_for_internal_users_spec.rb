require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180413022611_create_missing_namespace_for_internal_users.rb')

describe CreateMissingNamespaceForInternalUsers, :migration do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:routes) { table(:routes) }

  internal_user_types = [:ghost]
  internal_user_types << :support_bot if ActiveRecord::Base.connection.column_exists?(:users, :support_bot)

  internal_user_types.each do |attr|
    context "for #{attr} user" do
      let(:internal_user) do
        users.create!(email: 'test@example.com', projects_limit: 100, username: 'test', attr => true)
      end

      it 'creates the missing namespace' do
        expect(namespaces.find_by(owner_id: internal_user.id)).to be_nil

        migrate!

        namespace = Namespace.find_by(type: nil, owner_id: internal_user.id)
        route = namespace.route

        expect(namespace.path).to eq(route.path)
        expect(namespace.name).to eq(route.name)
      end

      it 'sets notification email' do
        users.update(internal_user.id, notification_email: nil)

        expect(users.find(internal_user.id).notification_email).to be_nil

        migrate!

        user = users.find(internal_user.id)
        expect(user.notification_email).to eq(user.email)
      end
    end
  end
end
