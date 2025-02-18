# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::ProjectScopeLink, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  it { is_expected.to belong_to(:source_project) }
  it { is_expected.to belong_to(:target_project) }
  it { is_expected.to belong_to(:added_by) }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:parent) { create(:user) }
    let!(:model) { create(:ci_job_token_project_scope_link, added_by: parent) }
  end

  it_behaves_like 'a BulkInsertSafe model', described_class do
    let(:current_time) { Time.zone.now }

    let(:valid_items_for_bulk_insertion) do
      build_list(:ci_job_token_project_scope_link, 10, source_project_id: project.id,
        created_at: current_time) do |project_scope_link|
        project_scope_link.target_project = create(:project)
      end
    end

    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe 'unique index' do
    let!(:link) { create(:ci_job_token_project_scope_link) }

    it 'raises an error, when not unique' do
      expect do
        create(:ci_job_token_project_scope_link,
          source_project: link.source_project,
          target_project: link.target_project,
          direction: link.direction)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '.create' do
    let_it_be(:target) { create(:project) }
    let(:new_link) { described_class.create(source_project: project, target_project: target) } # rubocop:disable Rails/SaveBang

    context 'when there are more than PROJECT_LINK_DIRECTIONAL_LIMIT existing links' do
      before do
        create_list(:ci_job_token_project_scope_link, 5, source_project: project)
        stub_const("#{described_class}::PROJECT_LINK_DIRECTIONAL_LIMIT", 3)
      end

      it 'invalidates new links and prevents them from being created' do
        expect { new_link }.not_to change { described_class.count }
        expect(new_link).not_to be_persisted
        expect(new_link.errors.full_messages)
          .to include('Source project exceeds the allowable number of project links in this direction')
      end

      it 'does not invalidate existing links' do
        expect(described_class.count).to be > described_class::PROJECT_LINK_DIRECTIONAL_LIMIT
        expect(described_class.all).to all(be_valid)
      end
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
        let(:link) { build(:ci_job_token_project_scope_link, job_token_policies: value) }

        it 'matches the json_schema for policies' do
          expect(link.valid?).to eq(valid)
        end
      end
    end
  end

  describe '.with_source' do
    subject { described_class.with_source(project) }

    let!(:source_link) { create(:ci_job_token_project_scope_link, source_project: project) }
    let!(:target_link) { create(:ci_job_token_project_scope_link, target_project: project) }

    it 'returns only the links having the given source project' do
      expect(subject).to contain_exactly(source_link)
    end
  end

  describe '.with_target' do
    subject { described_class.with_target(project) }

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

  describe 'enums' do
    let(:directions) { { outbound: 0, inbound: 1 } }

    it { is_expected.to define_enum_for(:direction).with_values(directions) }
  end

  context 'loose foreign key on ci_job_token_project_scope_links.source_project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project, namespace: group) }
      let!(:model) { create(:ci_job_token_project_scope_link, source_project: parent) }
    end
  end

  context 'loose foreign key on ci_job_token_project_scope_links.target_project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project, namespace: group) }
      let!(:model) { create(:ci_job_token_project_scope_link, target_project: parent) }
    end
  end
end
