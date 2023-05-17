# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Loaders::LazyRelationLoader, feature_category: :vulnerability_management do
  let(:query_context) { {} }
  let(:args) { {} }

  let_it_be(:project) { create(:project) }

  let(:loader) { loader_class.new(query_context, project, **args) }

  describe '#load' do
    subject(:load_relation) { loader.load }

    context 'when the association is has many' do
      let_it_be(:public_issue) { create(:issue, project: project) }
      let_it_be(:confidential_issue) { create(:issue, :confidential, project: project) }

      let(:loader_class) do
        Class.new(described_class) do
          self.model = Project
          self.association = :issues

          def relation(public_only: false)
            relation = base_relation
            relation = relation.public_only if public_only

            relation
          end
        end
      end

      it { is_expected.to be_an_instance_of(described_class::RelationProxy) }

      describe '#relation' do
        subject { load_relation.load }

        context 'without arguments' do
          it { is_expected.to contain_exactly(public_issue, confidential_issue) }
        end

        context 'with arguments' do
          let(:args) { { public_only: true } }

          it { is_expected.to contain_exactly(public_issue) }
        end
      end

      describe 'using the same context for different records' do
        let_it_be(:another_project) { create(:project) }

        let(:loader_for_another_project) { loader_class.new(query_context, another_project, **args) }
        let(:records_for_another_project) { loader_for_another_project.load.load }
        let(:records_for_project) { load_relation.load }

        before do
          loader # register the original loader to query context
        end

        it 'does not mix associated records' do
          expect(records_for_another_project).to be_empty
          expect(records_for_project).to contain_exactly(public_issue, confidential_issue)
        end

        it 'does not cause N+1 queries' do
          expect { records_for_another_project }.not_to exceed_query_limit(1)
        end
      end

      describe 'using Active Record querying methods' do
        subject { load_relation.limit(1).load.count }

        it { is_expected.to be(1) }
      end

      describe 'using Active Record finder methods' do
        subject { load_relation.last(2) }

        it { is_expected.to contain_exactly(public_issue, confidential_issue) }
      end

      describe 'calling a method that returns a non relation object' do
        subject { load_relation.limit(1).limit_value }

        it { is_expected.to be(1) }
      end

      describe 'calling a prohibited method' do
        subject(:count) { load_relation.count }

        it 'raises a `PrematureQueryExecutionTriggered` error' do
          expect { count }.to raise_error(described_class::Registry::PrematureQueryExecutionTriggered)
        end
      end
    end

    context 'when the association is has one' do
      let!(:project_setting) { create(:project_setting, project: project) }
      let(:loader_class) do
        Class.new(described_class) do
          self.model = Project
          self.association = :project_setting
        end
      end

      it { is_expected.to eq(project_setting) }
    end

    context 'when the association is belongs to' do
      let(:loader_class) do
        Class.new(described_class) do
          self.model = Project
          self.association = :namespace
        end
      end

      it 'raises error' do
        expect { load_relation }.to raise_error(RuntimeError)
      end
    end
  end
end
