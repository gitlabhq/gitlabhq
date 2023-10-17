# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Base::ObjectBuilder do
  let(:project) do
    create(
      :project, :repository,
      :builds_disabled,
      :issues_disabled,
      name: 'project',
      path: 'project'
    )
  end

  let(:klass) { Milestone }
  let(:attributes) { { 'title' => 'Test Base::ObjectBuilder Milestone', 'project' => project } }

  subject { described_class.build(klass, attributes) }

  describe '#build' do
    context 'when object exists' do
      context 'when where_clauses are implemented' do
        before do
          allow_next_instance_of(described_class) do |object_builder|
            allow(object_builder).to receive(:where_clauses).and_return([klass.arel_table['title'].eq(attributes['title'])])
          end
        end

        let!(:milestone) { create(:milestone, title: attributes['title'], project: project) }

        it 'finds existing object instead of creating one' do
          expect(subject).to eq(milestone)
        end
      end

      context 'when where_clauses are not implemented' do
        it 'raises NotImplementedError' do
          expect { subject }.to raise_error(NotImplementedError)
        end
      end
    end

    context 'when object does not exist' do
      before do
        allow_next_instance_of(described_class) do |object_builder|
          allow(object_builder).to receive(:find_object).and_return(nil)
        end
      end

      it 'creates new object' do
        expect { subject }.to change { Milestone.count }.from(0).to(1)
      end
    end
  end
end
