# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/no_find_in_workers'

RSpec.describe RuboCop::Cop::Gitlab::NoFindInWorkers, feature_category: :shared do
  context 'when find is used' do
    it 'adds an offense' do
      expect_offense(<<~CODE)
        class SomeWorker
          include ApplicationWorker

          def perform
            namespace = Namespace.find(namespace_id)
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Refrain from using `find`, use `find_by` instead. See https://docs.gitlab.com/ee/development/sidekiq/#retries.[...]
          end
        end
      CODE
    end
  end

  context 'when find is not used' do
    it 'adds no offense' do
      expect_no_offenses(<<~CODE)
        class SomeWorker
          include ApplicationWorker

          def perform
            namespace = Namespace.find_by(namespace_id)
            return unless namespace
          end
        end
      CODE
    end
  end
end
