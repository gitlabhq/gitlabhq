# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::ProjectScopeLink do
  it { is_expected.to belong_to(:source_project) }
  it { is_expected.to belong_to(:target_project) }
  it { is_expected.to belong_to(:added_by) }

  let_it_be(:project) { create(:project) }

  describe 'unique index' do
    let!(:link) { create(:ci_job_token_project_scope_link) }

    it 'raises an error' do
      expect do
        create(:ci_job_token_project_scope_link,
          source_project: link.source_project,
          target_project: link.target_project)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'validations' do
    it 'must have a source project', :aggregate_failures do
      link = build(:ci_job_token_project_scope_link, source_project: nil)

      expect(link).not_to be_valid
      expect(link.errors[:source_project]).to contain_exactly("can't be blank")
    end

    it 'must have a target project', :aggregate_failures do
      link = build(:ci_job_token_project_scope_link, target_project: nil)

      expect(link).not_to be_valid
      expect(link.errors[:target_project]).to contain_exactly("can't be blank")
    end

    it 'must have a target project different than source project', :aggregate_failures do
      link = build(:ci_job_token_project_scope_link, target_project: project, source_project: project)

      expect(link).not_to be_valid
      expect(link.errors[:target_project]).to contain_exactly("can't be the same as the source project")
    end
  end

  describe '.from_project' do
    subject { described_class.from_project(project) }

    let!(:source_link) { create(:ci_job_token_project_scope_link, source_project: project) }
    let!(:target_link) { create(:ci_job_token_project_scope_link, target_project: project) }

    it 'returns only the links having the given source project' do
      expect(subject).to contain_exactly(source_link)
    end
  end

  describe '.to_project' do
    subject { described_class.to_project(project) }

    let!(:source_link) { create(:ci_job_token_project_scope_link, source_project: project) }
    let!(:target_link) { create(:ci_job_token_project_scope_link, target_project: project) }

    it 'returns only the links having the given target project' do
      expect(subject).to contain_exactly(target_link)
    end
  end

  describe '.for_source_and_target' do
    let_it_be(:link) { create(:ci_job_token_project_scope_link, source_project: project) }

    subject { described_class.for_source_and_target(project, target_project) }

    context 'when link is found' do
      let(:target_project) { link.target_project }

      it { is_expected.to eq(link) }
    end

    context 'when link is not found' do
      let(:target_project) { create(:project) }

      it { is_expected.to be_nil }
    end
  end
end
