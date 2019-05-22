# frozen_string_literal: true

shared_examples 'labeled issues with labels and label_name params' do
  shared_examples 'returns label names' do
    it 'returns label names' do
      expect_paginated_array_response(issue.id)
      expect(json_response.first['labels']).to eq([label_c.title, label_b.title, label.title])
    end
  end

  shared_examples 'returns basic label entity' do
    it 'returns basic label entity' do
      expect_paginated_array_response(issue.id)
      expect(json_response.first['labels'].pluck('name')).to eq([label_c.title, label_b.title, label.title])
      expect(json_response.first['labels'].first).to match_schema('/public_api/v4/label_basic')
    end
  end

  context 'array of labeled issues when all labels match' do
    let(:params) { { labels: "#{label.title},#{label_b.title},#{label_c.title}" } }

    it_behaves_like 'returns label names'
  end

  context 'array of labeled issues when all labels match with labels param as array' do
    let(:params) { { labels: [label.title, label_b.title, label_c.title] } }

    it_behaves_like 'returns label names'
  end

  context 'when with_labels_details provided' do
    context 'array of labeled issues when all labels match' do
      let(:params) { { labels: "#{label.title},#{label_b.title},#{label_c.title}", with_labels_details: true } }

      it_behaves_like 'returns basic label entity'
    end

    context 'array of labeled issues when all labels match with labels param as array' do
      let(:params) { { labels: [label.title, label_b.title, label_c.title], with_labels_details: true } }

      it_behaves_like 'returns basic label entity'
    end
  end
end
