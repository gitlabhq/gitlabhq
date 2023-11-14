# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::UpdateTagsService, feature_category: :package_registry do
  let_it_be(:package, reload: true) { create(:nuget_package) }

  let(:tags) { %w[test-tag tag1 tag2 tag3] }
  let(:service) { described_class.new(package, tags) }

  describe '#execute' do
    subject { service.execute }

    RSpec.shared_examples 'updating tags' do |tags_count|
      it 'updates a tag' do
        expect { subject }.to change { Packages::Tag.count }.by(tags_count)
        expect(package.reload.tags.map(&:name)).to contain_exactly(*tags)
      end
    end

    it_behaves_like 'updating tags', 4

    context 'with an existing tag' do
      before do
        create(:packages_tag, package: package2, name: 'test-tag')
      end

      context 'on the same package' do
        let_it_be(:package2) { package }

        it_behaves_like 'updating tags', 3

        context 'with different name' do
          before do
            create(:packages_tag, package: package2, name: 'to_be_destroyed')
          end

          it_behaves_like 'updating tags', 2
        end
      end

      context 'on a different package' do
        let_it_be(:package2) { create(:nuget_package) }

        it_behaves_like 'updating tags', 4
      end
    end

    context 'with empty tags' do
      let(:tags) { [] }

      it 'is a no op' do
        expect(package).not_to receive(:tags)
        expect(::ApplicationRecord).not_to receive(:legacy_bulk_insert)

        subject
      end
    end
  end
end
