# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::Todo, feature_category: :notifications do
  using RSpec::Parameterized::TableSyntax

  let(:todo) { build_stubbed(:todo) }

  subject(:entity) { described_class.new(todo) }

  describe '#todo_target_class' do
    where(:type, :expected_entity) do
      "Issue" | API::Entities::Issue
      "Namespace" | API::Entities::Namespace
      "Key" | API::Entities::SSHKey
    end

    with_them do
      it "maps the type to the correct API entity" do
        expect(entity.todo_target_class(type)).to be(expected_entity)
      end
    end
  end
end
