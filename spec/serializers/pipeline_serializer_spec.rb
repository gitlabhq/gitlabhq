require 'spec_helper'

describe PipelineSerializer do
  let(:user) { create(:user) }

  let(:serializer) do
    described_class.new(user: user)
  end

  subject { serializer.represent(resource) }

  describe '#represent' do
    context 'when used without pagination' do
      it 'created a not paginated serializer' do
        expect(serializer).not_to be_paginated
      end

      context 'when a single object is being serialized' do
        let(:resource) { create(:ci_empty_pipeline) }

        it 'serializers the pipeline object' do
          expect(subject[:id]).to eq resource.id
        end
      end

      context 'when multiple objects are being serialized' do
        let(:resource) { create_list(:ci_pipeline, 2) }

        it 'serializers the array of pipelines' do
          expect(subject).not_to be_empty
        end
      end
    end

    context 'when used with pagination' do
      let(:request) { spy('request') }
      let(:response) { spy('response') }
      let(:pagination) { {} }

      before do
        allow(request)
          .to receive(:query_parameters)
          .and_return(pagination)
      end

      let(:serializer) do
        described_class.new(user: user)
          .with_pagination(request, response)
      end

      it 'created a paginated serializer' do
        expect(serializer).to be_paginated
      end

      context 'when resource is not paginatable' do
        context 'when a single pipeline object is being serialized' do
          let(:resource) { create(:ci_empty_pipeline) }
          let(:pagination) { { page: 1, per_page: 1 } }

          it 'raises error' do
            expect { subject }.to raise_error(
              Gitlab::Serializer::Pagination::InvalidResourceError)
          end
        end
      end

      context 'when resource is paginatable relation' do
        let(:resource) { Ci::Pipeline.all }
        let(:pagination) { { page: 1, per_page: 2 } }

        context 'when a single pipeline object is present in relation' do
          before { create(:ci_empty_pipeline) }

          it 'serializes pipeline relation' do
            expect(subject.first).to have_key :id
          end
        end

        context 'when a multiple pipeline objects are being serialized' do
          before { create_list(:ci_empty_pipeline, 3) }

          it 'serializes appropriate number of objects' do
            expect(subject.count).to be 2
          end

          it 'appends relevant headers' do
            expect(response).to receive(:[]=).with('X-Total', '3')
            expect(response).to receive(:[]=).with('X-Total-Pages', '2')
            expect(response).to receive(:[]=).with('X-Per-Page', '2')

            subject
          end
        end
      end
    end
  end
end
