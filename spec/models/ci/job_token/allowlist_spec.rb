# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Allowlist, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:source_project) { create(:project) }

  let(:allowlist) { described_class.new(source_project, direction: direction) }
  let(:direction) { :outbound }

  describe '#projects' do
    subject(:projects) { allowlist.projects }

    context 'when no projects are added to the scope' do
      [:inbound, :outbound].each do |d|
        let(:direction) { d }

        it 'returns the project defining the scope' do
          expect(projects).to contain_exactly(source_project)
        end
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with scoped projects'

      where(:direction, :additional_project) do
        :outbound | ref(:outbound_scoped_project)
        :inbound  | ref(:inbound_scoped_project)
      end

      with_them do
        it 'returns all projects that can be accessed from a given scope' do
          expect(projects).to contain_exactly(source_project, additional_project)
        end
      end
    end
  end

  describe '#includes?' do
    subject { allowlist.includes?(includes_project) }

    context 'without scoped projects' do
      let(:unscoped_project) { build(:project) }

      where(:includes_project, :direction, :result) do
        ref(:source_project)   | :outbound | false
        ref(:source_project)   | :inbound  | false
        ref(:unscoped_project) | :outbound | false
        ref(:unscoped_project) | :inbound  | false
      end

      with_them do
        it { is_expected.to be result }
      end
    end

    context 'with scoped projects' do
      include_context 'with scoped projects'

      where(:includes_project, :direction, :result) do
        ref(:source_project)          | :outbound | false
        ref(:source_project)          | :inbound  | false
        ref(:inbound_scoped_project)  | :outbound | false
        ref(:inbound_scoped_project)  | :inbound  | true
        ref(:outbound_scoped_project) | :outbound | true
        ref(:outbound_scoped_project) | :inbound  | false
        ref(:unscoped_project1)       | :outbound | false
        ref(:unscoped_project1)       | :inbound  | false
        ref(:unscoped_project2)       | :outbound | false
        ref(:unscoped_project2)       | :inbound  | false
      end

      with_them do
        it { is_expected.to be result }
      end
    end
  end
end
