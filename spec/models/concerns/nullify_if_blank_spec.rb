# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NullifyIfBlank do
  let_it_be(:model) do
    Class.new(ApplicationRecord) do
      include NullifyIfBlank

      nullify_if_blank :name

      self.table_name = 'users'
    end
  end

  context 'attribute exists' do
    let(:instance) { model.new(name: name) }

    subject { instance.name }

    before do
      instance.validate
    end

    context 'attribute is blank' do
      let(:name) { '' }

      it { is_expected.to be_nil }
    end

    context 'attribute is nil' do
      let(:name) { nil }

      it { is_expected.to be_nil }
    end

    context 'attribute is not blank' do
      let(:name) { 'name' }

      it { is_expected.to eq('name') }
    end
  end

  context 'attribute does not exist' do
    before do
      model.table_name = 'issues'
    end

    it { expect { model.new.valid? }.to raise_error(ActiveModel::UnknownAttributeError) }
  end
end
