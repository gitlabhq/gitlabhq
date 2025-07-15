# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GemExtensions::ActiveRecord::ConnectionAdapters::Transaction::TransactionCallbacks, feature_category: :shared do
  describe '.after_commit' do
    let(:collection) { [] }

    context 'with real transaction' do
      subject(:unit_of_work) do
        ApplicationRecord.transaction do
          ApplicationRecord.current_transaction.after_commit do
            collection << :after_commit
          end

          collection << :before_commit
        end
      end

      it 'executes the given block after the transaction commits' do
        unit_of_work

        expect(collection).to eq([:before_commit, :after_commit])
      end
    end

    context 'with savepoints' do
      context 'with joinable parent' do
        subject(:unit_of_work) do
          ApplicationRecord.transaction do
            ApplicationRecord.transaction(requires_new: requires_new) do
              ApplicationRecord.current_transaction.after_commit do
                collection << :after_commit
              end

              collection << :before_release
            end

            collection << :before_commit
          end
        end

        context 'with `requires_new: true`' do
          let(:requires_new) { true }

          it 'executes the given block after the transaction commits' do
            unit_of_work

            expect(collection).to eq([:before_release, :before_commit, :after_commit])
          end
        end

        context 'with `requires_new: false`' do
          let(:requires_new) { false }

          it 'executes the given block after the transaction commits' do
            unit_of_work

            expect(collection).to eq([:before_release, :before_commit, :after_commit])
          end
        end
      end

      context 'without joinable parent' do
        subject(:unit_of_work) do
          ApplicationRecord.transaction(joinable: false) do
            ApplicationRecord.transaction(requires_new: requires_new) do
              ApplicationRecord.current_transaction.after_commit do
                collection << :after_commit
              end

              collection << :before_release
            end

            collection << :before_commit
          end
        end

        context 'with `requires_new: true`' do
          let(:requires_new) { true }

          it 'executes the given block after the transaction commits' do
            unit_of_work

            expect(collection).to eq([:before_release, :after_commit, :before_commit])
          end
        end

        context 'with `requires_new: false`' do
          let(:requires_new) { false }

          it 'executes the given block after the transaction commits' do
            unit_of_work

            expect(collection).to eq([:before_release, :after_commit, :before_commit])
          end
        end
      end
    end
  end
end
