# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Allowlist, feature_category: :continuous_integration do
  include Ci::JobTokenScopeHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:source_project) { create(:project) }

  let(:allowlist) { described_class.new(source_project, direction: direction) }
  let(:direction) { :outbound }

  describe '#projects' do
    subject(:projects) { allowlist.projects }

    context 'when no projects are added to the scope' do
      [:inbound, :outbound].each do |d|
        context "with #{d}" do
          let(:direction) { d }

          it 'returns the project defining the scope' do
            expect(projects).to contain_exactly(source_project)
          end
        end
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with a project in each allowlist'

      where(:direction, :additional_project) do
        :outbound | ref(:outbound_allowlist_project)
        :inbound  | ref(:inbound_allowlist_project)
      end

      with_them do
        it 'returns all projects that can be accessed from a given scope' do
          expect(projects).to contain_exactly(source_project, additional_project)
        end
      end
    end
  end

  describe 'add!' do
    let_it_be(:added_project) { create(:project) }
    let_it_be(:user) { create(:user) }

    subject { allowlist.add!(added_project, user: user) }

    [:inbound, :outbound].each do |d|
      context "with #{d}" do
        let(:direction) { d }

        it 'adds the project' do
          subject

          expect(allowlist.projects).to contain_exactly(source_project, added_project)
          expect(subject.added_by_id).to eq(user.id)
          expect(subject.source_project_id).to eq(source_project.id)
          expect(subject.target_project_id).to eq(added_project.id)
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

    context 'with a project in each allowlist' do
      include_context 'with a project in each allowlist'

      where(:includes_project, :direction, :result) do
        ref(:source_project)          | :outbound | false
        ref(:source_project)          | :inbound  | false
        ref(:inbound_allowlist_project)  | :outbound | false
        ref(:inbound_allowlist_project)  | :inbound  | true
        ref(:outbound_allowlist_project) | :outbound | true
        ref(:outbound_allowlist_project) | :inbound  | false
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
