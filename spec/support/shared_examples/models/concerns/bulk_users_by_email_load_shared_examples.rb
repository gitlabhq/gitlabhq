# frozen_string_literal: true

RSpec.shared_examples 'a BulkUsersByEmailLoad model' do
  describe '#users_by_emails' do
    let_it_be(:user1) { create(:user, emails: [create(:email, email: 'user1@example.com')]) }
    let_it_be(:user2) { create(:user, emails: [create(:email, email: 'user2@example.com')]) }

    subject(:model) { described_class.new(id: non_existing_record_id) }

    context 'when nothing is loaded' do
      let(:passed_emails) { [user1.emails.first.email, user2.email] }

      it 'preforms the yielded query and supplies the data with only emails desired' do
        expect(model.users_by_emails(passed_emails).keys).to contain_exactly(*passed_emails)
      end
    end

    context 'when store is preloaded', :request_store do
      let(:passed_emails) { [user1.emails.first.email, user2.email, user1.email] }
      let(:resource_data) do
        {
          user1.emails.first.email => instance_double('User'),
          user2.email => instance_double('User')
        }
      end

      before do
        Gitlab::SafeRequestStore["user_by_email_for_users:#{model.class.name}:#{model.id}"] = resource_data
      end

      it 'passes back loaded data and does not update the items that already exist' do
        users_by_emails = model.users_by_emails(passed_emails)

        expect(users_by_emails.keys).to contain_exactly(*passed_emails)
        expect(users_by_emails).to include(resource_data.merge(user1.email => user1))
      end
    end
  end
end
