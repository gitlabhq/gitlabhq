# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::GroupScopeLink, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  it { is_expected.to belong_to(:target_group) }
  it { is_expected.to belong_to(:source_project) }
  it { is_expected.to belong_to(:added_by) }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:parent) { create(:user) }
    let!(:model) { create(:ci_job_token_group_scope_link, added_by: parent) }
  end

  it_behaves_like 'a BulkInsertSafe model', described_class do
    let(:current_time) { Time.zone.now }

    let(:valid_items_for_bulk_insertion) do
      build_list(:ci_job_token_group_scope_link, 10, source_project_id: project.id,
        created_at: current_time) do |project_scope_link|
        project_scope_link.target_group = create(:group)
      end
    end

    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe 'unique index' do
    let!(:link) { create(:ci_job_token_group_scope_link) }

    it 'raises an error, when not unique' do
      expect do
        create(:ci_job_token_group_scope_link,
          source_project: link.source_project,
          target_group: link.target_group
        )
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '.create' do
    let_it_be(:target) { create(:group) }
    let(:new_link) { described_class.new(source_project: project, target_group: target) }

    context 'when there are more than GROUP_LINK_LIMIT existing links' do
      before do
        create_list(:ci_job_token_group_scope_link, 5, source_project: project)
        stub_const("#{described_class}::GROUP_LINK_LIMIT", 3)
      end

      it 'invalidates new links and prevents them from being created' do
        expect do
          new_link.save!
        end
        .to raise_error(ActiveRecord::RecordInvalid,
          'Validation failed: Source project exceeds the allowable number of group links')

        expect(new_link).not_to be_persisted
      end

      it 'does not invalidate existing links' do
        expect(described_class.count).to be > described_class::GROUP_LINK_LIMIT
        expect(described_class.all).to all(be_valid)
      end
    end
  end

  describe 'validations' do
    it 'must have a source project', :aggregate_failures do
      link = build(:ci_job_token_group_scope_link, source_project: nil)

      expect(link).not_to be_valid
      expect(link.errors[:source_project]).to contain_exactly("can't be blank")
    end

    it 'must have a target group', :aggregate_failures do
      link = build(:ci_job_token_group_scope_link, target_group: nil)

      expect(link).not_to be_valid
      expect(link.errors[:target_group]).to contain_exactly("can't be blank")
    end

    describe 'job token policies' do
      using RSpec::Parameterized::TableSyntax

      where(:value, :valid) do
        nil                               | true
        []                                | true
        %w[read_containers]               | true
        %w[read_containers read_packages] | true
        %w[read_issue]                    | false
        { project: %w[read_build] }       | false
      end

      with_them do
        let(:link) { build(:ci_job_token_group_scope_link, job_token_policies: value) }

        it 'matches the json_schema for policies' do
          expect(link.valid?).to eq(valid)
        end
      end
    end
  end

  describe '.with_source' do
    let(:group_scope_link) { described_class.with_source(project) }

    let!(:source_link) { create(:ci_job_token_group_scope_link, source_project: project) }
    let!(:target_link) { create(:ci_job_token_group_scope_link, target_group: group) }

    it 'returns only the links having the given source project' do
      expect(group_scope_link).to contain_exactly(source_link)
    end
  end

  describe '.with_target' do
    let(:group_scope_link) { described_class.with_target(group) }

    let!(:source_link) { create(:ci_job_token_group_scope_link, source_project: project) }
    let!(:target_link) { create(:ci_job_token_group_scope_link, target_group: group) }

    it 'returns only the links having the given target group' do
      expect(group_scope_link).to contain_exactly(target_link)
    end
  end

  describe '.for_source_and_target' do
    let_it_be(:link) { create(:ci_job_token_group_scope_link, source_project: project) }

    subject { described_class.for_source_and_target(project, target_group) }

    context 'when link is found' do
      let(:target_group) { link.target_group }

      it { is_expected.to eq(link) }
    end

    context 'when link is not found' do
      let(:target_group) { create(:group) }

      it { is_expected.to be_nil }
    end
  end

  context 'when group gets deleted, it loses the foreign key on ci_job_token_group_scope_links.target_group_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:group) }
      let_it_be(:model) { create(:ci_job_token_group_scope_link, target_group: parent) }
    end
  end

  context 'when project gets deleted, it looses the foreign key on ci_job_token_group_scope_links.source_project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:project, namespace: group) }
      let_it_be(:model) { create(:ci_job_token_project_scope_link, source_project: parent) }
    end
  end
end
