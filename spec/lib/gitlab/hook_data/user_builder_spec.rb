# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::UserBuilder do
  let_it_be(:user) { create(:user, name: 'John Doe', username: 'johndoe', email: 'john@example.com') }

  describe '#build' do
    let(:data) { described_class.new(user).build(event) }
    let(:event_name) { data[:event_name] }
    let(:attributes) do
      [
        :event_name, :created_at, :updated_at, :name, :email, :user_id, :username
      ]
    end

    context 'data' do
      shared_examples_for 'includes the required attributes' do
        it 'includes the required attributes' do
          expect(data).to include(*attributes)

          expect(data[:name]).to eq('John Doe')
          expect(data[:email]).to eq('john@example.com')
          expect(data[:user_id]).to eq(user.id)
          expect(data[:username]).to eq('johndoe')
          expect(data[:created_at]).to eq(user.created_at.xmlschema)
          expect(data[:updated_at]).to eq(user.updated_at.xmlschema)
        end
      end

      shared_examples_for 'does not include old username attributes' do
        it 'does not include old username attributes' do
          expect(data).not_to include(:old_username)
        end
      end

      shared_examples_for 'does not include state attributes' do
        it 'does not include state attributes' do
          expect(data).not_to include(:state)
        end
      end

      context 'on create' do
        let(:event) { :create }

        it { expect(event_name).to eq('user_create') }

        it_behaves_like 'includes the required attributes'
        it_behaves_like 'does not include old username attributes'
        it_behaves_like 'does not include state attributes'
      end

      context 'on destroy' do
        let(:event) { :destroy }

        it { expect(event_name).to eq('user_destroy') }

        it_behaves_like 'includes the required attributes'
        it_behaves_like 'does not include old username attributes'
        it_behaves_like 'does not include state attributes'
      end

      context 'on rename' do
        let(:event) { :rename }

        it { expect(event_name).to eq('user_rename') }

        it_behaves_like 'includes the required attributes'
        it_behaves_like 'does not include state attributes'

        it 'includes old username details' do
          allow(user).to receive(:username_before_last_save).and_return('old-username')

          expect(data[:old_username]).to eq(user.username_before_last_save)
        end
      end

      context 'on failed_login' do
        let(:event) { :failed_login }

        it { expect(event_name).to eq('user_failed_login') }

        it_behaves_like 'includes the required attributes'
        it_behaves_like 'does not include old username attributes'

        it 'includes state details' do
          user.ldap_block!

          expect(data[:state]).to eq('ldap_blocked')
        end
      end
    end
  end
end
