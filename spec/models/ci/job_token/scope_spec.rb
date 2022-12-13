# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Scope, feature_category: :continuous_integration do
  let_it_be(:source_project) { create(:project, ci_outbound_job_token_scope_enabled: true) }

  let(:scope) { described_class.new(source_project) }

  describe '#all_projects' do
    subject(:all_projects) { scope.all_projects }

    context 'when no projects are added to the scope' do
      it 'returns the project defining the scope' do
        expect(all_projects).to contain_exactly(source_project)
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with scoped projects'

      it 'returns all projects that can be accessed from a given scope' do
        expect(subject).to contain_exactly(source_project, outbound_scoped_project)
      end
    end
  end

  describe '#allows?' do
    subject { scope.allows?(includes_project) }

    context 'without scoped projects' do
      context 'when self referential' do
        let(:includes_project) { source_project }

        it { is_expected.to be_truthy }
      end
    end

    context 'with scoped projects' do
      include_context 'with scoped projects'

      context 'when project is in outbound scope' do
        let(:includes_project) { outbound_scoped_project }

        it { is_expected.to be_truthy }
      end

      context 'when project is in inbound scope' do
        let(:includes_project) { inbound_scoped_project }

        it { is_expected.to be_falsey }
      end

      context 'when project is linked to a different project' do
        let(:includes_project) { unscoped_project1 }

        it { is_expected.to be_falsey }
      end

      context 'when project is unlinked to a project' do
        let(:includes_project) { unscoped_project2 }

        it { is_expected.to be_falsey }
      end

      context 'when project scope setting is disabled' do
        let(:includes_project) { unscoped_project1 }

        before do
          source_project.ci_outbound_job_token_scope_enabled = false
        end

        it 'considers any project to be part of the scope' do
          expect(subject).to be_truthy
        end
      end
    end
  end
end
