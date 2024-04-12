# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::SetNamespaceCommitEmailService, feature_category: :user_profile do
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, reporters: user) }
  let_it_be(:email) { create(:email, user: user) }
  let_it_be(:existing_achievement) { create(:achievement, namespace: group) }

  let(:namespace) { group }
  let(:current_user) { user }
  let(:target_user) { user }
  let(:email_id) { email.id }
  let(:params) { { user: target_user } }
  let(:service) { described_class.new(current_user, namespace, email_id, params) }

  shared_examples 'success' do
    it 'creates namespace commit email' do
      result = service.execute

      expect(result.payload[:namespace_commit_email]).to be_a(Users::NamespaceCommitEmail)
      expect(result.payload[:namespace_commit_email]).to be_persisted
    end
  end

  describe '#execute' do
    context 'when current_user is not provided' do
      let(:current_user) { nil }

      it 'returns error message' do
        expect(service.execute.message)
          .to eq("User doesn't exist or you don't have permission to change namespace commit emails.")
      end
    end

    context 'when current_user does not have permission to change namespace commit emails' do
      let(:target_user) { create(:user) }

      it 'returns error message' do
        expect(service.execute.message)
          .to eq("User doesn't exist or you don't have permission to change namespace commit emails.")
      end
    end

    context 'when target_user does not have permission to access the namespace' do
      let(:namespace) { create(:group, :private) }

      it 'returns error message' do
        expect(service.execute.message).to eq("Namespace doesn't exist or you don't have permission.")
      end
    end

    context 'when namespace is public' do
      let(:namespace) { create(:group, :public) }

      it_behaves_like 'success'
    end

    context 'when namespace is not provided' do
      let(:namespace) { nil }

      it 'returns error message' do
        expect(service.execute.message).to eq('Namespace must be provided.')
      end
    end

    context 'when target user is not current user' do
      context 'when current user is an admin' do
        let(:current_user) { create(:user, :admin) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'creates namespace commit email' do
            result = service.execute

            expect(result.payload[:namespace_commit_email]).to be_a(Users::NamespaceCommitEmail)
            expect(result.payload[:namespace_commit_email]).to be_persisted
          end
        end

        context 'when admin mode is not enabled' do
          it 'returns error message' do
            expect(service.execute.message)
              .to eq("User doesn't exist or you don't have permission to change namespace commit emails.")
          end
        end
      end

      context 'when current user is not an admin' do
        let(:current_user) { create(:user) }

        it 'returns error message' do
          expect(service.execute.message)
            .to eq("User doesn't exist or you don't have permission to change namespace commit emails.")
        end
      end
    end

    context 'when namespace commit email does not exist' do
      context 'when email_id is not provided' do
        let(:email_id) { nil }

        it 'returns error message' do
          expect(service.execute.message).to eq('Email must be provided.')
        end
      end

      context 'when model save fails' do
        before do
          allow_next(::Users::NamespaceCommitEmail).to receive(:save).and_return(false)
        end

        it 'returns error message' do
          expect(service.execute.message).to eq('Failed to save namespace commit email.')
        end
      end

      context 'when namepsace is a group' do
        it_behaves_like 'success'
      end

      context 'when namespace is a user' do
        let(:namespace) { current_user.namespace }

        it_behaves_like 'success'
      end

      context 'when namespace is a project' do
        let_it_be(:project) { create(:project) }

        let(:namespace) { project.project_namespace }

        before do
          project.add_reporter(current_user)
        end

        it_behaves_like 'success'
      end
    end

    context 'when namespace commit email already exists' do
      let!(:existing_namespace_commit_email) do
        create(:namespace_commit_email,
          user: target_user,
          namespace: namespace,
          email: create(:email, user: target_user))
      end

      context 'when email_id is not provided' do
        let(:email_id) { nil }

        it 'destroys the namespace commit email' do
          result = service.execute

          expect(result.message).to be_nil
          expect(result.payload[:namespace_commit_email]).to be_nil
        end
      end

      context 'and email_id is provided' do
        let(:email_id) { create(:email, user: current_user).id }

        it 'updates namespace commit email' do
          result = service.execute

          existing_namespace_commit_email.reload

          expect(result.payload[:namespace_commit_email]).to eq(existing_namespace_commit_email)
          expect(existing_namespace_commit_email.email_id).to eq(email_id)
        end
      end

      context 'when model save fails' do
        before do
          allow_any_instance_of(::Users::NamespaceCommitEmail).to receive(:save).and_return(false) # rubocop:disable RSpec/AnyInstanceOf
        end

        it 'returns generic error message' do
          expect(service.execute.message).to eq('Failed to save namespace commit email.')
        end

        context 'with model errors' do
          before do
            allow_any_instance_of(::Users::NamespaceCommitEmail).to receive_message_chain(:errors, :empty?).and_return(false) # rubocop:disable RSpec/AnyInstanceOf
            allow_any_instance_of(::Users::NamespaceCommitEmail).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return('Model error') # rubocop:disable RSpec/AnyInstanceOf
          end

          it 'returns the model error message' do
            expect(service.execute.message).to eq('Model error')
          end
        end
      end
    end
  end
end
