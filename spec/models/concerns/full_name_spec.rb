require 'spec_helper'

describe Project, 'FullName', caching: true do
  subject { create(:empty_project) }

  let(:namespace) { subject.namespace }
  let(:full_name) { "#{namespace.human_name} / #{subject.name}" }
  let(:new_name) { "#{namespace.human_name} / wow" }

  it { is_expected.to respond_to :full_name_changed? }

  describe '#full_name' do
    it { expect(subject.full_name).to eq(full_name) }
  end

  describe '#_uncached_full_name' do
    it { expect(subject._uncached_full_name).to eq(full_name) }

    it 'returns new value even if its not saved yet' do
      subject.name = 'wow'
      expect(subject._uncached_full_name).to eq(new_name)
    end
  end

  describe '#expire_name_cache' do
    before { subject.name = 'wow' }

    it 'returns new value after expire_name_cache executed' do
      expect(subject.full_name).to eq(full_name)

      subject.expire_name_cache

      expect(subject.full_name).to eq(new_name)
    end

    it 'expires cache automatically when object is saved' do
      subject.save

      expect(subject.full_name).to eq(new_name)
    end
  end
end

describe Group, 'FullName', caching: true do
  subject { create(:group, :nested) }

  let(:parent) { subject.parent }
  let(:full_name) { "#{parent.full_name} / #{subject.name}" }

  describe '#full_name' do
    it { expect(subject.full_name).to eq(full_name) }
  end
end
