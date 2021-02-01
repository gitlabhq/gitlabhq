# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Loaders::LabelsLoader do
  describe '#load' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:entity) { create(:bulk_import_entity, group: group) }
    let(:context) do
      BulkImports::Pipeline::Context.new(
        entity: entity,
        current_user: user
      )
    end

    let(:data) do
      {
        'title' => 'label',
        'description' => 'description',
        'color' => '#FFFFFF'
      }
    end

    it 'creates the label' do
      expect { subject.load(context, data) }.to change(Label, :count).by(1)

      label = group.labels.first

      expect(label.title).to eq(data['title'])
      expect(label.description).to eq(data['description'])
      expect(label.color).to eq(data['color'])
    end
  end
end
