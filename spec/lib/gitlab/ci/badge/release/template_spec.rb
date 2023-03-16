# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Badge::Release::Template do
  let(:project) { create(:project) }
  let(:ref) { 'v1.2.3' }
  let(:user) { create(:user) }
  let!(:release) { create(:release, tag: ref, project: project) }
  let(:badge) { Gitlab::Ci::Badge::Release::LatestRelease.new(project, user) }
  let(:template) { described_class.new(badge) }

  before do
    project.add_guest(user)
  end

  describe '#key_text' do
    it 'defaults to latest release' do
      expect(template.key_text).to eq 'Latest Release'
    end

    it 'returns custom key text' do
      key_text = 'Test Release'
      badge = Gitlab::Ci::Badge::Release::LatestRelease.new(project, user, opts: { key_text: key_text })

      expect(described_class.new(badge).key_text).to eq key_text
    end
  end

  describe '#value_text' do
    context 'when a release exists' do
      it 'returns the tag of the release' do
        expect(template.value_text).to eq ref
      end
    end

    context 'no releases exist' do
      before do
        allow(badge).to receive(:tag).and_return(nil)
      end

      it 'returns string that latest release is none' do
        expect(template.value_text).to eq 'none'
      end
    end
  end

  describe '#key_width' do
    it 'returns the default key width' do
      expect(template.key_width).to eq 90
    end

    it 'returns custom key width' do
      key_width = 100
      badge = Gitlab::Ci::Badge::Release::LatestRelease.new(project, user, opts: { key_width: key_width })

      expect(described_class.new(badge).key_width).to eq key_width
    end
  end

  describe '#value_width' do
    it 'returns the default value width' do
      expect(template.value_width).to eq 54
    end

    it 'returns custom value width' do
      value_width = 100
      badge = Gitlab::Ci::Badge::Release::LatestRelease.new(project, user, opts: { value_width: value_width })

      expect(described_class.new(badge).value_width).to eq value_width
    end

    it 'returns VALUE_WIDTH_DEFAULT if the custom value_width supplied is greater than permissible limit' do
      value_width = 250
      badge = Gitlab::Ci::Badge::Release::LatestRelease.new(project, user, opts: { value_width: value_width })

      expect(described_class.new(badge).value_width).to eq 54
    end

    it 'returns VALUE_WIDTH_DEFAULT if value_width is not a number' do
      value_width = "string"
      badge = Gitlab::Ci::Badge::Release::LatestRelease.new(project, user, opts: { value_width: value_width })

      expect(described_class.new(badge).value_width).to eq 54
    end
  end

  describe '#key_color' do
    it 'always has the same color' do
      expect(template.key_color).to eq '#555'
    end
  end

  describe '#value_color' do
    context 'when release exists' do
      it 'is blue' do
        expect(template.value_color).to eq '#3076af'
      end
    end

    context 'when release does not exist' do
      before do
        allow(badge).to receive(:tag).and_return(nil)
      end

      it 'is red' do
        expect(template.value_color).to eq '#e05d44'
      end
    end
  end
end
