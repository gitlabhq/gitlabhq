# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Scope, feature_category: :continuous_integration, factory_default: :keep do
  include Ci::JobTokenScopeHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create_default(:project) }
  let_it_be(:user) { create_default(:user) }
  let_it_be(:namespace) { create_default(:namespace) }

  let_it_be(:source_project) do
    create(:project,
      ci_outbound_job_token_scope_enabled: true,
      ci_inbound_job_token_scope_enabled: true
    )
  end

  let(:current_project) { source_project }

  let(:scope) { described_class.new(current_project) }

  describe '#outbound_projects' do
    subject { scope.outbound_projects }

    context 'when no projects are added to the scope' do
      it 'returns the project defining the scope' do
        expect(subject).to contain_exactly(current_project)
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with accessible and inaccessible projects'

      it 'returns all projects that can be accessed from a given scope' do
        expect(subject).to contain_exactly(current_project, outbound_allowlist_project, fully_accessible_project)
      end
    end
  end

  describe '#inbound_projects' do
    subject { scope.inbound_projects }

    context 'when no projects are added to the scope' do
      it 'returns the project defining the scope' do
        expect(subject).to contain_exactly(current_project)
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with accessible and inaccessible projects'

      it 'returns all projects that can be accessed from a given scope' do
        expect(subject).to contain_exactly(current_project, inbound_allowlist_project)
      end
    end
  end

  describe '#groups' do
    subject { scope.groups }

    context 'when no groups are added to the scope' do
      it 'returns an empty list' do
        expect(subject).to be_empty
      end
    end

    context 'when groups are added to the scope' do
      let_it_be(:target_group) { create(:group) }

      include_context 'with projects that are with and without groups added in allowlist'

      with_them do
        it 'returns all groups that are allowed access in the job token scope' do
          expect(subject).to contain_exactly(target_group)
        end
      end
    end
  end

  describe 'accessible?' do
    subject { scope.accessible?(accessed_project) }

    context 'with groups in allowlist' do
      let_it_be(:target_group) { create(:group) }
      let_it_be(:target_project) do
        create(:project,
          ci_inbound_job_token_scope_enabled: true,
          group: target_group
        )
      end

      let(:scope) { described_class.new(target_project) }

      include_context 'with projects that are with and without groups added in allowlist'

      where(:accessed_project, :result) do
        ref(:project_with_target_project_group_in_allowlist)            | true
        ref(:project_wo_target_project_group_in_allowlist)              | false
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end

    context 'with inbound and outbound scopes enabled' do
      context 'when inbound and outbound access setup' do
        include_context 'with accessible and inaccessible projects'

        where(:accessed_project, :result) do
          ref(:current_project)            | true
          ref(:inbound_allowlist_project)  | false
          ref(:unscoped_project1)          | false
          ref(:unscoped_project2)          | false
          ref(:outbound_allowlist_project) | false
          ref(:inbound_accessible_project) | false
          ref(:fully_accessible_project)   | true
          ref(:unscoped_public_project)    | false
        end

        with_them do
          it 'allows self and projects allowed from both directions' do
            is_expected.to eq(result)
          end
        end
      end
    end

    context 'with inbound scope enabled and outbound scope disabled' do
      before do
        accessed_project.update!(ci_inbound_job_token_scope_enabled: true)
        current_project.update!(ci_outbound_job_token_scope_enabled: false)
      end

      include_context 'with accessible and inaccessible projects'

      where(:accessed_project, :result) do
        ref(:current_project)            | true
        ref(:inbound_allowlist_project)  | false
        ref(:unscoped_project1)          | false
        ref(:unscoped_project2)          | false
        ref(:outbound_allowlist_project) | false
        ref(:inbound_accessible_project) | true
        ref(:fully_accessible_project)   | true
        ref(:unscoped_public_project)    | false
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end

    context 'with inbound scope disabled and outbound scope enabled' do
      before do
        accessed_project.update!(ci_inbound_job_token_scope_enabled: false)
        current_project.update!(ci_outbound_job_token_scope_enabled: true)
      end

      include_context 'with accessible and inaccessible projects'

      where(:accessed_project, :result) do
        ref(:current_project)            | true
        ref(:inbound_allowlist_project)  | false
        ref(:unscoped_project1)          | false
        ref(:unscoped_project2)          | false
        ref(:outbound_allowlist_project) | true
        ref(:inbound_accessible_project) | false
        ref(:fully_accessible_project)   | true
        ref(:unscoped_public_project)    | true
      end

      with_them do
        it { is_expected.to eq(result) }
      end
    end
  end
end
