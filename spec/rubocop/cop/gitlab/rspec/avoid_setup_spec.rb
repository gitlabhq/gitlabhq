# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../../rubocop/cop/gitlab/rspec/avoid_setup'

RSpec.describe RuboCop::Cop::Gitlab::RSpec::AvoidSetup do
  context 'when calling let_it_be' do
    let(:source) do
      <<~SRC
        let_it_be(:user) { create(:user) }
        ^^^^^^^^^^^^^^^^ Avoid the use of `let_it_be` [...]
      SRC
    end

    it 'registers an offense' do
      expect_offense(source)
    end
  end

  context 'without readability issues' do
    let(:source) do
      <<~SRC
        it 'registers the user and sends them to a project listing page' do
          user_signs_up

          expect_to_see_account_confirmation_page
        end
      SRC
    end

    it 'does not register an offense' do
      expect_no_offenses(source)
    end
  end
end
