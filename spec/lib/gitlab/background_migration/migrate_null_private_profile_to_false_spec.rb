# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateNullPrivateProfileToFalse, :migration, schema: 20190620105427 do
  let(:users) { table(:users) }

  it 'correctly migrates nil private_profile to false' do
    private_profile_true = users.create!(private_profile: true, projects_limit: 1, email: 'a@b.com')
    private_profile_false = users.create!(private_profile: false, projects_limit: 1, email: 'b@c.com')
    private_profile_nil = users.create!(private_profile: nil, projects_limit: 1, email: 'c@d.com')

    described_class.new.perform(private_profile_true.id, private_profile_nil.id)

    private_profile_true.reload
    private_profile_false.reload
    private_profile_nil.reload

    expect(private_profile_true.private_profile).to eq(true)
    expect(private_profile_false.private_profile).to eq(false)
    expect(private_profile_nil.private_profile).to eq(false)
  end
end
