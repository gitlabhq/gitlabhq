# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/ee_only_class'

RSpec.describe RuboCop::Cop::Gitlab::EeOnlyClass, feature_category: :shared do
  describe 'bad examples' do
    shared_examples 'reference offense' do
      it 'registers an offense' do
        expect_offense(<<~CODE, file_name)
          module EE
            class NullNotificationService
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This area is meant for extending CE [...]
              def execute
              end
            end
          end
        CODE
      end
    end

    context 'when class is defined and matches the file basename' do
      let(:file_name) { 'ee/app/services/ee/null_notification_service.rb' }

      include_examples 'reference offense'
    end
  end

  describe 'good examples' do
    context 'when class is defined and does not match file basename' do
      let(:file_name) { 'ee/app/services/ee/some_extended_ce_code.rb' }

      it 'does not register an offense' do
        expect_no_offenses(<<~CODE, file_name)
          module EE
            module SomeExtendedCeCode
              def execute
              end

              class NullNotificationService
                def execute
                end
              end
            end
          end
        CODE
      end
    end
  end
end
