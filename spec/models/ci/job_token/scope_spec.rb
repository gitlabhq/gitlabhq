# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Scope do
  let_it_be(:project) { create(:project) }

  let(:scope) { described_class.new(project) }

  describe '#all_projects' do
    subject(:all_projects) { scope.all_projects }

    context 'when no projects are added to the scope' do
      it 'returns the project defining the scope' do
        expect(all_projects).to contain_exactly(project)
      end
    end

    context 'when other projects are added to the scope' do
      let_it_be(:scoped_project) { create(:project) }
      let_it_be(:unscoped_project) { create(:project) }

      let!(:link_in_scope) { create(:ci_job_token_project_scope_link, source_project: project, target_project: scoped_project) }
      let!(:link_out_of_scope) { create(:ci_job_token_project_scope_link, target_project: unscoped_project) }

      it 'returns all projects that can be accessed from a given scope' do
        expect(subject).to contain_exactly(project, scoped_project)
      end
    end
  end

  describe '#includes?' do
    subject { scope.includes?(target_project) }

    context 'when param is the project defining the scope' do
      let(:target_project) { project }

      it { is_expected.to be_truthy }
    end

    context 'when param is a project in scope' do
      let(:target_link) { create(:ci_job_token_project_scope_link, source_project: project) }
      let(:target_project) { target_link.target_project }

      it { is_expected.to be_truthy }
    end

    context 'when param is a project in another scope' do
      let(:scope_link) { create(:ci_job_token_project_scope_link) }
      let(:target_project) { scope_link.target_project }

      it { is_expected.to be_falsey }

      context 'when project scope setting is disabled' do
        before do
          project.ci_job_token_scope_enabled = false
        end

        it 'considers any project to be part of the scope' do
          expect(subject).to be_truthy
        end
      end
    end
  end
end
