# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/gitlab/avoid_current_organization'

RSpec.describe RuboCop::Cop::Gitlab::AvoidCurrentOrganization, feature_category: :cell do
  describe 'bad examples' do
    shared_examples 'reference offense' do
      it 'registers an offense' do
        expect_offense(<<~CODE, node: node_value)
          return if %{node}
                    ^{node} Avoid the use of [...]
        CODE
      end
    end

    context 'when referencing Current.organization' do
      let(:node_value) { 'Current.organization' }

      include_examples 'reference offense'
    end

    context 'when referencing Current.organization_id' do
      let(:node_value) { 'Current.organization_id' }

      include_examples 'reference offense'
    end

    context 'when assigning Current.organization=' do
      let(:node_value) { 'Current.organization' }

      it 'registers an offense' do
        expect_offense(<<~CODE, keyword: node_value)
          %{keyword} = some_value
          ^{keyword}^^^^^^^^^^^^^ Avoid the use of [...]
        CODE
      end
    end
  end

  describe 'good examples' do
    it 'does not register an offense' do
      expect_no_offenses('Current.organization_thing')
    end
  end
end
