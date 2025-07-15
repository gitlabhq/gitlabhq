# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Builder::Release do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:release) { create(:release, project: project) }

  let(:builder) { described_class.new(release) }

  describe '#variables' do
    let(:description_variable) do
      {
        key: 'CI_RELEASE_DESCRIPTION',
        value: release.description,
        public: true,
        masked: false,
        raw: true
      }
    end

    let(:name_variable) do
      {
        key: 'CI_RELEASE_NAME',
        value: release.name,
        public: true,
        masked: false,
        raw: false
      }
    end

    subject do
      builder.variables
    end

    context 'when the release is present' do
      let(:description_item) { item(description_variable) }
      let(:name_item) { item(name_variable) }

      it 'contains all the variables' do
        is_expected.to contain_exactly(description_item, name_item)
      end

      context 'for large description' do
        before do
          release.update_attribute(:description, "Test Description ..." * 5000)
        end

        it 'truncates' do
          expect(subject['CI_RELEASE_DESCRIPTION'].value.length).to eq(1024)
        end
      end

      context 'when description is nil' do
        before do
          release.update_attribute(:description, nil)
        end

        it 'returns without error' do
          builder = subject

          expect(builder.errors).to be_nil
        end

        it 'is not included' do
          expect(subject.to_hash).not_to have_key('CI_RELEASE_DESCRIPTION')
        end
      end
    end

    context 'when the release is not present' do
      let(:release) { nil }

      it 'contains no variables' do
        is_expected.to match_array([])
      end
    end
  end

  def item(variable)
    ::Gitlab::Ci::Variables::Collection::Item.fabricate(variable)
  end
end
