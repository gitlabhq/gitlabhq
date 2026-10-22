# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::JobArtifactAccessPolicy, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :public, public_builds: true) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }

  let(:access) { Authz::JobArtifactAccess.new(project: project, accessibility: accessibility, file_type: 'junit') }

  subject(:policy) { described_class.new(user, access) }

  describe 'delegation' do
    let(:user) { nil }
    let(:accessibility) { 'public' }

    it { is_expected.to delegate_to(ProjectPolicy) }
    it { expect(described_class).to override_delegates_for(:read_job_artifacts) }
  end

  where(:user, :accessibility, :allowed) do
    nil              | 'public'     | true
    nil              | 'private'    | false
    ref(:reporter)   | 'public'     | true
    ref(:reporter)   | 'private'    | false
    ref(:developer)  | 'private'    | true
    ref(:developer)  | 'maintainer' | false
    ref(:developer)  | 'none'       | false
    ref(:maintainer) | 'maintainer' | true
    ref(:maintainer) | 'none'       | false
  end

  with_them do
    it { is_expected.to(allowed ? be_allowed(:read_job_artifacts) : be_disallowed(:read_job_artifacts)) }
  end

  context 'when artifacts share the same access attributes', :request_store do
    let_it_be(:artifacts) do
      Array.new(3) { create(:ci_job_artifact, :junit, job: create(:ci_build, project: project)) }
    end

    it 'evaluates the policy once' do
      expect(described_class).to receive(:new).once.and_call_original

      artifacts.each { |artifact| Ability.allowed?(developer, :read_job_artifacts, artifact) }
    end
  end
end
