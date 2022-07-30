# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleaseHighlights::Validator::Entry do
  subject(:entry) { described_class.new(document.root.children.first) }

  let(:document) { YAML.parse(File.read(yaml_path)) }
  let(:yaml_path) { 'spec/fixtures/whats_new/blank.yml' }

  describe 'validations' do
    before do
      allow(entry).to receive(:value_for).and_call_original
    end

    context 'with a valid entry' do
      let(:yaml_path) { 'spec/fixtures/whats_new/valid.yml' }

      it { is_expected.to be_valid }
    end

    context 'with an invalid entry' do
      let(:yaml_path) { 'spec/fixtures/whats_new/invalid.yml' }

      it 'returns line numbers in errors' do
        subject.valid?

        expect(entry.errors[:available_in].first).to match('(line 6)')
      end
    end

    context 'with a blank entry' do
      it 'validate presence of name, description and stage' do
        subject.valid?

        expect(subject.errors[:name]).not_to be_empty
        expect(subject.errors[:description]).not_to be_empty
        expect(subject.errors[:stage]).not_to be_empty
        expect(subject.errors[:available_in]).not_to be_empty
      end

      it 'validates boolean value of "self-managed" and "gitlab-com"' do
        allow(entry).to receive(:value_for).with(:'self-managed').and_return('nope')
        allow(entry).to receive(:value_for).with(:'gitlab-com').and_return('yerp')

        subject.valid?

        expect(subject.errors[:'self-managed']).to include(/must be a boolean/)
        expect(subject.errors[:'gitlab-com']).to include(/must be a boolean/)
      end

      it 'validates URI of "url" and "image_url"' do
        stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')
        allow(entry).to receive(:value_for).with(:image_url).and_return('https://foobar.x/images/ci/gitlab-ci-cd-logo_2x.png')
        allow(entry).to receive(:value_for).with(:documentation_link).and_return('')

        subject.valid?

        expect(subject.errors[:documentation_link]).to include(/must be a valid URL/)
        expect(subject.errors[:image_url]).to include(/is blocked: Host cannot be resolved or invalid/)
      end

      it 'validates release is numerical' do
        allow(entry).to receive(:value_for).with(:release).and_return('one')

        subject.valid?

        expect(subject.errors[:release]).to include(/is not a number/)
      end

      it 'validates published_at is a date' do
        allow(entry).to receive(:value_for).with(:published_at).and_return('christmas day')

        subject.valid?

        expect(subject.errors[:published_at]).to include(/must be valid Date/)
      end

      it 'validates available_in are included in list' do
        allow(entry).to receive(:value_for).with(:available_in).and_return(['ALL'])

        subject.valid?

        expect(subject.errors[:available_in].first).to include("must be one of", "Free", "Premium", "Ultimate")
      end
    end
  end
end
