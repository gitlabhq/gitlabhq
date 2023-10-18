# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::RelatedWorkItemLink, type: :model, feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:work_item, :issue, project: project) }

  it_behaves_like 'issuable link' do
    let_it_be_with_reload(:issuable_link) { create(:work_item_link) }
    let_it_be(:issuable) { issue }
    let_it_be(:issuable2) { create(:work_item, :issue, project: project) }
    let_it_be(:issuable3) { create(:work_item, :issue, project: project) }
    let(:issuable_class) { 'WorkItem' }
    let(:issuable_link_factory) { :work_item_link }
  end

  it_behaves_like 'includes LinkableItem concern' do
    let_it_be(:item) { create(:work_item, project: project) }
    let_it_be(:item1) { create(:work_item, project: project) }
    let_it_be(:item2) { create(:work_item, project: project) }
    let_it_be(:link_factory) { :work_item_link }
    let_it_be(:item_type) { described_class.issuable_name }
  end

  describe '.issuable_type' do
    it { expect(described_class.issuable_type).to eq(:issue) }
  end

  describe '.issuable_name' do
    it { expect(described_class.issuable_name).to eq('work item') }
  end

  describe 'validations' do
    describe '#validate_related_link_restrictions' do
      using RSpec::Parameterized::TableSyntax

      where(:source_type_sym, :target_types, :valid) do
        :incident  | [:incident, :test_case, :issue, :task, :ticket] | false
        :ticket    | [:incident, :test_case, :issue, :task, :ticket] | false
        :test_case | [:incident, :test_case, :issue, :task, :ticket] | false
        :task      | [:incident, :test_case, :ticket]                | false
        :issue     | [:incident, :test_case, :ticket]                | false
        :task      | [:task, :issue]                                 | true
        :issue     | [:task, :issue]                                 | true
      end

      with_them do
        it 'validates the related link' do
          target_types.each do |target_type_sym|
            source_type = WorkItems::Type.default_by_type(source_type_sym)
            target_type = WorkItems::Type.default_by_type(target_type_sym)
            source = build(:work_item, work_item_type: source_type, project: project)
            target = build(:work_item, work_item_type: target_type, project: project)
            link = build(:work_item_link, source: source, target: target)
            opposite_link = build(:work_item_link, source: target, target: source)

            expect(link.valid?).to eq(valid)
            expect(opposite_link.valid?).to eq(valid)
            next if valid

            expect(link.errors.messages[:source]).to contain_exactly(
              "#{source_type.name.downcase.pluralize} cannot be related to #{target_type.name.downcase.pluralize}"
            )
          end
        end
      end
    end
  end
end
