# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureGate do
  describe '.actor_from_id' do
    using RSpec::Parameterized::TableSyntax

    subject(:actor_from_id) { model_class.actor_from_id(model_id) }

    where(:model_class, :model_id, :expected) do
      Project                      | 1 | 'Project:1'
      Group                        | 2 | 'Group:2'
      User                         | 3 | 'User:3'
      Ci::Runner                   | 4 | 'Ci::Runner:4'
      Namespace                    | 5 | 'Namespace:5'
      Namespaces::ProjectNamespace | 6 | 'Namespaces::ProjectNamespace:6'
      Namespaces::UserNamespace    | 7 | 'Namespaces::UserNamespace:7'
    end

    with_them do
      it 'returns an object that has the correct flipper_id' do
        expect(actor_from_id).to have_attributes(flipper_id: expected)
      end
    end
  end

  describe '#flipper_id' do
    where(:factory) { %i[project group user ci_runner namespace] }

    with_them do
      it 'returns nil when object is not persisted' do
        actor = build(factory)

        expect(actor.flipper_id).to be_nil
      end

      it 'returns flipper_id when object is persisted' do
        # rubocop:disable Rails/SaveBang -- This is FactoryBot#create, not ActiveModel#create.
        actor = create(factory)
        # rubocop:enable Rails/SaveBang

        expect(actor.flipper_id).to eq("#{actor.class.name}:#{actor.id}")
      end
    end
  end
end
