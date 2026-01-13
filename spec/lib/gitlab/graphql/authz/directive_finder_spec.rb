# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::DirectiveFinder, feature_category: :permissions do
  include Authz::GranularTokenAuthorizationHelper

  let(:directive) { create_directive(boundary: 'project', permissions: ['READ_ISSUE']) }
  let(:field_with_directive) { create_field_with_directive(directive:) }
  let(:object) { nil }

  subject(:finder) { described_class.new(field) }

  describe '#find' do
    subject(:find) { finder.find(object) }

    context 'when no directive is found' do
      let(:field) { create_base_field }

      it { is_expected.to be_nil }
    end

    context 'when directive is on the field' do
      let(:field) { field_with_directive }

      it { is_expected.to eq(directive) }
    end

    context 'when directive is on the field owner' do
      let(:field) { create_base_field(owner: field_with_directive) }

      it { is_expected.to eq(directive) }
    end

    context 'when directive is on the implementing type' do
      let(:field) { create_base_field(owner: create_interface) }
      let(:model) { build(:issue) }
      let(:object) { instance_double(Types::BaseObject, object: model) }

      before do
        allow(GitlabSchema).to receive(:types).and_return(model.class.name => field_with_directive)
      end

      it { is_expected.to eq(directive) }

      context 'when object is a model' do
        let(:object) { model }

        it { is_expected.to eq(directive) }
      end

      context 'when object is nil' do
        let(:object) { nil }

        it { is_expected.to be_nil }
      end

      context 'when object is wrapped in a presenter' do
        let(:presenter) { IssuePresenter.new(model, current_user: nil) }
        let(:object) { instance_double(Types::BaseObject, object: presenter) }

        it 'unwraps the presenter and finds the directive' do
          expect(find).to eq(directive)
        end
      end

      context 'when the implementing type is not found in the schema' do
        before do
          allow(GitlabSchema).to receive(:types).and_return({})
        end

        it { is_expected.to be_nil }
      end

      context 'when field owner is nil' do
        let(:field) { create_base_field(owner: nil) }

        it { is_expected.to be_nil }
      end

      context 'when field owner kind is nil' do
        let(:owner) { class_double(GraphQL::Schema::Object, kind: nil) }
        let(:field) { create_base_field(owner: owner) }

        it { is_expected.to be_nil }
      end
    end

    context 'when directive is on the return type' do
      let(:return_type) do
        Class.new(GraphQL::Schema::Object) { graphql_name 'TestReturnType' }.tap do |type|
          allow(type).to receive(:directives).and_return([directive])
        end
      end

      let(:field) { create_base_field(type: return_type) }

      it { is_expected.to eq(directive) }
    end
  end
end
