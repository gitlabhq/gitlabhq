# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatAnchorsHelper, feature_category: :groups_and_projects do
  let(:anchor_klass) { ProjectPresenter::AnchorData }

  describe '#stat_anchor_attrs' do
    subject { helper.stat_anchor_attrs(anchor) }

    context 'when anchor is a link' do
      let(:anchor) { anchor_klass.new(true) }

      it 'returns the proper attributes' do
        expect(subject[:class]).to include('stat-link !gl-px-0 !gl-pb-2')
      end
    end

    context 'when anchor is not a link' do
      context 'when class_modifier is set' do
        let(:anchor) { anchor_klass.new(false, nil, nil, 'btn-default') }

        it 'returns the proper attributes' do
          expect(subject[:class]).to include('stat-link !gl-px-0 !gl-pb-2 btn-default')
        end
      end

      context 'when class_modifier is not set' do
        let(:anchor) { anchor_klass.new(false) }

        it 'returns the proper attributes' do
          expect(subject[:class]).to include('stat-link !gl-px-0 !gl-pb-2 btn-link gl-button !gl-text-link')
        end
      end
    end

    context 'when itemprop is not set' do
      let(:anchor) { anchor_klass.new(false, nil, nil, nil, nil, false) }

      it 'returns the itemprop attributes' do
        expect(subject[:itemprop]).to be_nil
      end
    end

    context 'when itemprop is set set' do
      let(:anchor) { anchor_klass.new(false, nil, nil, nil, nil, true) }

      it 'returns the itemprop attributes' do
        expect(subject[:itemprop]).to eq true
      end
    end

    context 'when data is not set' do
      let(:anchor) { anchor_klass.new(false, nil, nil, nil, nil, nil, nil) }

      it 'returns the data attributes' do
        expect(subject[:data]).to be_nil
      end
    end

    context 'when itemprop is set' do
      let(:anchor) { anchor_klass.new(false, nil, nil, nil, nil, nil, { 'toggle' => 'modal' }) }

      it 'returns the data attributes' do
        expect(subject[:data]).to eq({ 'toggle' => 'modal' })
      end
    end
  end
end
