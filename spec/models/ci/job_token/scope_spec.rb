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

  describe 'add!' do
    let_it_be(:new_project) { create(:project) }

    subject { scope.add!(new_project, direction: direction, user: user) }

    [:inbound, :outbound].each do |d|
      context "with #{d}" do
        let(:direction) { d }

        it 'adds the project' do
          subject

          expect(scope.send("#{direction}_projects")).to contain_exactly(current_project, new_project)
        end
      end
    end

    # Context and before block can go away leaving just the example in 16.0
    context 'with inbound only enabled' do
      before do
        project.ci_cd_settings.update!(job_token_scope_enabled: false)
      end

      it 'provides access' do
        expect do
          scope.add!(new_project, direction: :inbound, user: user)
        end.to change { described_class.new(new_project).accessible?(current_project) }.from(false).to(true)
      end
    end
  end

  RSpec.shared_examples 'enforces outbound scope only' do
    include_context 'with accessible and inaccessible projects'

    where(:accessed_project, :result) do
      ref(:current_project)            | true
      ref(:inbound_allowlist_project)  | false
      ref(:unscoped_project1)          | false
      ref(:unscoped_project2)          | false
      ref(:outbound_allowlist_project) | true
      ref(:inbound_accessible_project) | false
      ref(:fully_accessible_project)   | true
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe 'accessible?' do
    subject { scope.accessible?(accessed_project) }

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

      include_examples 'enforces outbound scope only'
    end
  end
end
