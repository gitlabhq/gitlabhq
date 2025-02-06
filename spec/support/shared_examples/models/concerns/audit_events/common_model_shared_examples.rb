# frozen_string_literal: true

RSpec.shared_examples 'includes ::AuditEvents::CommonModel concern' do
  describe 'associations' do
    it { is_expected.to belong_to(:user).with_foreign_key(:author_id).inverse_of(:audit_events) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:author_id) }

    include_examples 'validates IP address' do
      let(:attribute) { :ip_address }
      let(:object) { create(audit_event_symbol) } # rubocop:disable Rails/SaveBang -- Method not available
    end
  end

  describe 'callbacks' do
    describe '#truncate_fields' do
      shared_examples 'a truncated field' do
        context 'when values are provided' do
          using RSpec::Parameterized::TableSyntax

          where(:database_column, :details_value, :expected_value) do
            :long  | nil    | :truncated
            :short | nil    | :short
            nil    | :long  | :truncated
            nil    | :short | :short
            :long  | :short | :truncated
          end

          with_them do
            let(:values) do
              {
                long: 'a' * (field_limit + 1),
                short: 'a' * field_limit,
                truncated: "#{'a' * (field_limit - 3)}..."
              }
            end

            let(:audit_event) do
              create(audit_event_symbol,
                field_name => values[database_column],
                details: { field_name => values[details_value] }
              )
            end

            it 'sets both values to be the same', :aggregate_failures do
              expect(audit_event.send(field_name)).to eq(values[expected_value])
              expect(audit_event.details[field_name]).to eq(values[expected_value])
            end
          end
        end

        context 'when values are not provided' do
          let(:audit_event) do
            create(:audit_event, field_name => nil, details: {})
          end

          it 'does not set', :aggregate_failures do
            expect(audit_event.send(field_name)).to be_nil
            expect(audit_event.details).not_to have_key(field_name)
          end
        end
      end

      context 'for entity_path' do
        let(:field_name) { :entity_path }
        let(:field_limit) { 5_500 }

        it_behaves_like 'a truncated field'
      end

      context 'for target_details' do
        let(:field_name) { :target_details }
        let(:field_limit) { 5_500 }

        it_behaves_like 'a truncated field'
      end
    end

    describe '#parallel_persist' do
      shared_examples 'a parallel persisted field' do
        using RSpec::Parameterized::TableSyntax

        where(:column, :details, :expected_value) do
          :value | nil | :value
          nil    | :value         | :value
          :value | :another_value | :value
          nil    | nil            | nil
        end

        with_them do
          let(:values) { { value: value, another_value: "#{value}88" } }

          let(:audit_event) do
            build(audit_event_symbol, name => values[column], details: { name => values[details] })
          end

          it 'sets both values to be the same', :aggregate_failures do
            audit_event.validate

            expect(audit_event[name]).to eq(values[expected_value])
            expect(audit_event.details[name]).to eq(values[expected_value])
          end
        end
      end

      context 'with author_name' do
        let(:name) { :author_name }
        let(:value) { 'Mary Poppins' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with target_details' do
        let(:name) { :target_details }
        let(:value) { 'gitlab-org/gitlab' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with target_type' do
        let(:name) { :target_type }
        let(:value) { 'Project' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with target_id' do
        let(:name) { :target_id }
        let(:value) { 8 }

        it_behaves_like 'a parallel persisted field'
      end
    end
  end

  describe '.order_by' do
    let_it_be(:event_1) { create(audit_event_symbol) }  # rubocop:disable Rails/SaveBang -- Method not available
    let_it_be(:event_2) { create(audit_event_symbol) }  # rubocop:disable Rails/SaveBang -- Method not available
    let_it_be(:event_3) { create(audit_event_symbol) }  # rubocop:disable Rails/SaveBang -- Method not available

    subject(:events) { audit_event_class.order_by(method) }

    context 'when sort by created_at in ascending order' do
      let(:method) { 'created_asc' }

      it 'sorts results by id in ascending order' do
        expect(events).to eq([event_1, event_2, event_3])
      end
    end

    context 'when it is default' do
      let(:method) { nil }

      it 'sorts results by id in descending order' do
        expect(events.count).to eq(3)
        expect(events).to eq([event_3, event_2, event_1])
      end
    end
  end

  it 'sanitizes custom_message in the details hash' do
    audit_event = create(audit_event_symbol, details: { target_id: 678, custom_message: '<strong>Arnold</strong>' })

    expect(audit_event.details).to include(
      target_id: 678,
      custom_message: 'Arnold'
    )
  end

  describe '#as_json' do
    context 'for ip_address' do
      subject { build(audit_event_symbol, ip_address: '192.168.1.1').as_json }

      it 'overrides the ip_address with its string value' do
        expect(subject['ip_address']).to eq('192.168.1.1')
      end
    end
  end

  describe '#author_name' do
    context 'when user exists' do
      let(:user) { create(:user, name: 'John Doe') }
      let(:event) { build(:audit_events_user_audit_event, user: user) }

      it 'returns user name' do
        expect(event.author_name).to eq('John Doe')
      end
    end

    context 'when user does not exist anymore' do
      context 'when database contains author_name' do
        subject(:event) { build(audit_event_symbol, author_id: non_existing_record_id, author_name: 'Jane Doe') }

        it 'returns author_name' do
          expect(event.author_name).to eq 'Jane Doe'
        end
      end

      context 'when details contains author_name' do
        subject(:event) do
          build(audit_event_symbol, author_id: non_existing_record_id, author_name: nil,
            details: { author_name: 'John Doe' })
        end

        it 'returns author_name' do
          expect(event.author_name).to eq 'John Doe'
        end
      end

      context 'when details does not contains author_name' do
        subject(:event) do
          build(audit_event_symbol, author_name: nil,
            details: {})
        end

        it 'returns nil' do
          expect(subject.author_name).to eq nil
        end
      end
    end

    context 'when authored by an unauthenticated user' do
      subject(:event) { build(audit_event_symbol, author_name: nil, details: {}, author_id: -1) }

      it 'returns `An unauthenticated user`' do
        expect(subject.author_name).to eq('An unauthenticated user')
      end
    end
  end

  describe '#ip_address' do
    context 'when ip_address exists in both details hash and ip_address column' do
      subject(:event) do
        build(audit_event_symbol, ip_address: '10.2.1.1', details: { ip_address: '192.168.0.1' })
      end

      it 'returns the value from ip_address column' do
        expect(event.ip_address).to eq('10.2.1.1')
      end
    end

    context 'when ip_address exists in details hash but not in ip_address column' do
      subject(:event) { build(audit_event_symbol, ip_address: nil, details: { ip_address: '192.168.0.1' }) }

      it 'returns the value from details hash' do
        expect(event.ip_address).to eq('192.168.0.1')
      end
    end
  end

  describe '#entity_path' do
    context 'when entity_path exists in both details hash and entity_path column' do
      subject(:event) do
        build(audit_event_symbol, entity_path: 'gitlab-org/gitlab', details: { entity_path: 'gitlab-org/gitlab-foss' })
      end

      it 'returns the value from entity_path column' do
        expect(event.entity_path).to eq('gitlab-org/gitlab')
      end
    end

    context 'when entity_path exists in details hash but not in entity_path column' do
      subject(:event) do
        build(audit_event_symbol, entity_path: nil, details: { entity_path: 'gitlab-org/gitlab-foss' })
      end

      it 'returns the value from details hash' do
        expect(event.entity_path).to eq('gitlab-org/gitlab-foss')
      end
    end
  end

  describe '#target_type' do
    context 'when target_type exists in both details hash and target_type column' do
      subject(:event) do
        build(audit_event_symbol, target_type: 'Group', details: { target_type: 'Project' })
      end

      it 'returns the value from target_type column' do
        expect(event.target_type).to eq('Group')
      end
    end

    context 'when target_type exists in details hash but not in target_type column' do
      subject(:event) { build(audit_event_symbol, details: { target_type: 'Project' }) }

      it 'returns the value from details hash' do
        expect(event.target_type).to eq('Project')
      end
    end
  end

  describe '#formatted_details' do
    subject(:event) do
      create(audit_event_symbol, details: { change: 'membership_lock', from: false, to: true, ip_address: '127.0.0.1' })
    end

    it 'includes the author\'s email' do
      expect(event.formatted_details[:author_email]).to eq(event.author.email)
    end

    it 'converts value of `to` and `from` in `details` to string' do
      expect(event.formatted_details[:to]).to eq('true')
      expect(event.formatted_details[:from]).to eq('false')
    end
  end
end
