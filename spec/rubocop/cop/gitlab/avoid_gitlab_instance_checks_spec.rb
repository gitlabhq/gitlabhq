# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/gitlab/avoid_gitlab_instance_checks'

RSpec.describe RuboCop::Cop::Gitlab::AvoidGitlabInstanceChecks, feature_category: :shared do
  let(:msg) { described_class::MSG }

  describe 'bad examples' do
    where(:code) do
      %w[
        Gitlab.com?
        Gitlab.com_except_jh?
        Gitlab.com_and_canary?
        Gitlab.com_but_not_canary?
        Gitlab.org_or_com?
        ::Gitlab.com?
        Gitlab::CurrentSettings.should_check_namespace_plan?
        ::Gitlab::CurrentSettings.should_check_namespace_plan?
        Gitlab::Saas.enabled?
        ::Gitlab::Saas.enabled?
      ]
    end

    with_them do
      it 'registers an offense' do
        expect_offense(<<~CODE, node: code)
          return if %{node}
                    ^{node} Avoid the use of [...]
        CODE
      end
    end
  end

  describe 'good examples' do
    where(:code) do
      %w[com? com Gitlab.com Gitlab::CurrentSettings.check_namespace_plan?]
    end

    with_them do
      it 'does not register an offense' do
        expect_no_offenses(code)
      end
    end
  end
end
