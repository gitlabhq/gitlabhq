require 'spec_helper'

describe Project, 'FullPath', caching: true do
  subject { create(:empty_project) }

  let(:namespace) { subject.namespace }
  let(:full_path) { "#{namespace.full_path}/#{subject.path}" }
  let(:new_path) { "#{namespace.full_path}/wow" }

  it { is_expected.to respond_to :full_path_changed? }

  describe '#full_path' do
    it { expect(subject.full_path).to eq(full_path) }
  end

  describe '#_uncached_full_path' do
    it { expect(subject._uncached_full_path).to eq(full_path) }

    it 'returns new value even if its not saved yet' do
      subject.path = 'wow'
      expect(subject._uncached_full_path).to eq(new_path)
    end
  end

  describe '#expire_path_cache' do
    before { subject.path = 'wow' }

    it 'returns new value after expire_path_cache executed' do
      expect(subject.full_path).to eq(full_path)

      subject.expire_path_cache

      expect(subject.full_path).to eq(new_path)
    end

    it 'expires cache automatically when object is saved' do
      subject.save

      expect(subject.full_path).to eq(new_path)
    end
  end
end

describe Group, 'FullPath', caching: true do
  subject { create(:group, :nested) }

  let(:parent) { subject.parent }
  let(:full_path) { "#{parent.full_path}/#{subject.path}" }

  describe '#full_path' do
    it { expect(subject.full_path).to eq(full_path) }
  end
end
