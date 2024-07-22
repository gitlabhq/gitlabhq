# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::SourceUserMapper, feature_category: :importers do
  describe '#find_or_create_internal_user' do
    let_it_be(:namespace) { create(:namespace) }

    let_it_be(:import_type) { 'github' }
    let_it_be(:source_hostname) { 'github.com' }
    let_it_be(:source_name) { 'Pry Contributor' }
    let_it_be(:source_username) { 'a_pry_contributor' }
    let_it_be(:source_user_identifier) { '123456' }

    subject(:find_or_create_internal_user) do
      described_class.new(
        namespace: namespace,
        import_type: import_type,
        source_hostname: source_hostname
      ).find_or_create_internal_user(
        source_name: source_name,
        source_username: source_username,
        source_user_identifier: source_user_identifier
      )
    end

    shared_examples 'creates an import_source_user and a unique placeholder user' do
      it 'creates a import_source_user with an internal placeholder user' do
        expect { find_or_create_internal_user }.to change { Import::SourceUser.count }.from(2).to(3)

        new_import_source_user = Import::SourceUser.last

        expect(new_import_source_user.placeholder_user.user_type).to eq('placeholder')
        expect(new_import_source_user.attributes).to include({
          'namespace_id' => namespace.id,
          'import_type' => import_type,
          'source_hostname' => source_hostname,
          'source_name' => source_name,
          'source_username' => source_username,
          'source_user_identifier' => source_user_identifier
        })
      end

      it 'creates a new placeholder user with a unique email and username' do
        expect { find_or_create_internal_user }.to change { User.where(user_type: :placeholder).count }.from(0).to(1)

        new_placeholder_user = User.where(user_type: :placeholder).last

        expect(new_placeholder_user.name).to eq("Placeholder #{source_name}")
        expect(new_placeholder_user.username).to match(/^aprycontributor_placeholder_user_\d+$/)
        expect(new_placeholder_user.email).to match(/^aprycontributor_placeholder_user_\d+@#{Settings.gitlab.host}$/)
      end
    end

    shared_examples 'it does not create an import_source_user or placeholder user' do
      it 'does not create a import_source_user' do
        expect { find_or_create_internal_user }.not_to change { Import::SourceUser.count }
      end

      it 'does not create any internal users' do
        expect { find_or_create_internal_user }.not_to change { User.count }
      end
    end

    context 'when the placeholder user limit has not been reached' do
      let_it_be(:import_source_user_from_another_import) { create(:import_source_user) }
      let_it_be(:different_source_user_from_same_import) do
        create(:import_source_user,
          namespace_id: namespace.id,
          import_type: import_type,
          source_hostname: source_hostname,
          source_user_identifier: '999999'
        )
      end

      it_behaves_like 'creates an import_source_user and a unique placeholder user'

      context 'when retried and another placeholder user is not created while waiting' do
        before do
          allow_next_instance_of(described_class) do |source_user_mapper|
            allow(source_user_mapper).to receive(:in_lock).and_yield(true)
          end
        end

        it_behaves_like 'creates an import_source_user and a unique placeholder user'
      end

      context 'when retried and another placeholder user was made while waiting' do
        let_it_be(:existing_import_source_user) do
          create(
            :import_source_user,
            :with_placeholder_user,
            namespace: namespace,
            import_type: import_type,
            source_hostname: source_hostname,
            source_user_identifier: '123456')
        end

        before do
          allow_next_instance_of(described_class) do |source_user_mapper|
            allow(source_user_mapper).to receive(:in_lock).and_yield(true)
          end

          allow(Import::SourceUser).to receive(:find_source_user).and_return(nil, existing_import_source_user)
        end

        it 'returns the existing placeholder user' do
          expect(find_or_create_internal_user).to eq(existing_import_source_user.placeholder_user)
        end

        it_behaves_like 'it does not create an import_source_user or placeholder user'
      end

      context 'and an import source user exists for current import source' do
        context 'and the source user maps to a placeholder user' do
          let_it_be(:existing_import_source_user) do
            create(
              :import_source_user,
              :with_placeholder_user,
              namespace: namespace,
              import_type: import_type,
              source_hostname: source_hostname,
              source_user_identifier: '123456')
          end

          it 'returns the existing placeholder user' do
            expect(find_or_create_internal_user).to eq(existing_import_source_user.placeholder_user)
          end

          it_behaves_like 'it does not create an import_source_user or placeholder user'
        end

        context 'and the source_user maps to a reassigned user' do
          let_it_be(:existing_import_source_user) do
            create(
              :import_source_user,
              :with_reassign_to_user,
              namespace: namespace,
              import_type: import_type,
              source_hostname: source_hostname,
              source_user_identifier: '123456')
          end

          before do
            allow_next_found_instance_of(Import::SourceUser) do |source_user|
              allow(source_user).to receive(:accepted_status?).and_return(accepted)
            end
          end

          context 'when reassigned user has accepted the mapping' do
            let(:accepted) { true }

            it_behaves_like 'it does not create an import_source_user or placeholder user'

            it 'returns the existing reassign to user' do
              expect(find_or_create_internal_user).to eq(existing_import_source_user.reassign_to_user)
            end
          end

          context 'when reassigned user has not accepted the mapping' do
            let(:accepted) { false }

            it_behaves_like 'it does not create an import_source_user or placeholder user'

            it 'returns the existing placeholder user' do
              expect(find_or_create_internal_user).to eq(existing_import_source_user.placeholder_user)
            end
          end
        end
      end
    end
  end
end
