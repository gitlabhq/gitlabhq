# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabelSerializer do
  let(:user) { create(:user) }

  let(:serializer) do
    described_class.new(user: user)
  end

  subject { serializer.represent(resource) }

  describe '#represent' do
    context 'when a single object is being serialized' do
      let(:resource) { create(:label) }

      it 'serializes the label object' do
        expect(subject[:id]).to eq resource.id
      end
    end

    context 'when multiple objects are being serialized' do
      let(:num_labels) { 2 }
      let(:resource) { create_list(:label, num_labels) }

      it 'serializes the array of labels' do
        expect(subject.size).to eq(num_labels)
      end
    end
  end

  describe '#represent_appearance' do
    context 'when represents only appearance' do
      let(:resource) { create(:label) }

      subject { serializer.represent_appearance(resource) }

      it 'serializes only attributes used for appearance' do
        expect(subject.keys).to match_array([:id, :title, :color, :project_id, :text_color])
        expect(subject[:id]).to eq(resource.id)
        expect(subject[:title]).to eq(resource.title)
        expect(subject[:color]).to be_color(resource.color)
        expect(subject[:text_color]).to eq(resource.text_color)
        expect(subject[:project_id]).to eq(resource.project_id)
      end
    end
  end
end
