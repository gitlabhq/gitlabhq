# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateCanonicalEmails, :migration, schema: 20200312053852 do
  let(:migration) { described_class.new }

  let_it_be(:users_table) { table(:users) }
  let_it_be(:user_canonical_emails_table) { table(:user_canonical_emails) }

  let_it_be(:users) { users_table.all }
  let_it_be(:user_canonical_emails) { user_canonical_emails_table.all }

  subject { migration.perform(1, 1) }

  describe 'gmail users' do
    using RSpec::Parameterized::TableSyntax

    where(:original_email, :expected_result) do
      'legitimateuser@gmail.com'                            | 'legitimateuser@gmail.com'
      'userwithplus+somestuff@gmail.com'                    | 'userwithplus@gmail.com'
      'user.with.periods@gmail.com'                         | 'userwithperiods@gmail.com'
      'user.with.periods.and.plus+someotherstuff@gmail.com' | 'userwithperiodsandplus@gmail.com'
    end

    with_them do
      it 'generates the correct canonical email' do
        create_user(email: original_email, id: 1)

        subject

        result = canonical_emails
        expect(result.count).to eq 1
        expect(result.first).to match({
          'user_id' => 1,
          'canonical_email' => expected_result
        })
      end
    end
  end

  describe 'non gmail.com domain users' do
    %w[
      legitimateuser@somedomain.com
      userwithplus+somestuff@other.com
      user.with.periods@gmail.org
      user.with.periods.and.plus+someotherstuff@orangmail.com
    ].each do |non_gmail_address|
      it 'does not generate a canonical email' do
        create_user(email: non_gmail_address, id: 1)

        subject

        expect(canonical_emails(user_id: 1).count).to eq 0
      end
    end
  end

  describe 'gracefully handles missing records' do
    specify { expect { subject }.not_to raise_error }
  end

  describe 'gracefully handles existing records, some of which may have an already-existing identical canonical_email field' do
    let_it_be(:user_one) { create_user(email: "example.user@gmail.com", id: 1) }
    let_it_be(:user_two) { create_user(email: "exampleuser@gmail.com", id: 2) }
    let_it_be(:user_email_one) { user_canonical_emails.create!(canonical_email: "exampleuser@gmail.com", user_id: user_one.id) }

    subject { migration.perform(1, 2) }

    it 'only creates one record' do
      subject

      expect(canonical_emails.count).not_to be_nil
    end
  end

  def create_user(attributes)
    default_attributes = {
        projects_limit: 0
    }

    users.create!(default_attributes.merge!(attributes))
  end

  def canonical_emails(user_id: nil)
    filter_by_id = user_id ? "WHERE user_id = #{user_id}" : ""

    ApplicationRecord.connection.execute <<~SQL
      SELECT canonical_email, user_id
      FROM user_canonical_emails
      #{filter_by_id};
    SQL
  end
end
