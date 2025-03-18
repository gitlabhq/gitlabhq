# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::ExpandedJobTokenPolicies, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let(:scope) { scope_link_class.new(job_token_policies: job_token_policies) }

  subject { scope.expanded_job_token_policies }

  where(:scope_link_class, :job_token_policies, :result) do
    ::Ci::JobToken::GroupScopeLink   | %w[admin_jobs read_packages] | %i[admin_jobs read_jobs read_packages]
    ::Ci::JobToken::ProjectScopeLink | %w[admin_jobs read_packages] | %i[admin_jobs read_jobs read_packages]
  end

  with_them do
    it { is_expected.to match_array(result) }
  end
end
