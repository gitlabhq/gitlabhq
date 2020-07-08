# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Go::Module, type: :model do
  before do
    stub_feature_flags(go_proxy_disable_gomod_validation: false)
  end

  describe '#path_valid?' do
    context 'with root path' do
      let_it_be(:package) { create(:go_module) }

      context 'with major version 0' do
        it('returns true') { expect(package.path_valid?(0)).to eq(true) }
      end

      context 'with major version 1' do
        it('returns true') { expect(package.path_valid?(1)).to eq(true) }
      end

      context 'with major version 2' do
        it('returns false') { expect(package.path_valid?(2)).to eq(false) }
      end
    end

    context 'with path ./v2' do
      let_it_be(:package) { create(:go_module, path: '/v2') }

      context 'with major version 0' do
        it('returns false') { expect(package.path_valid?(0)).to eq(false) }
      end

      context 'with major version 1' do
        it('returns false') { expect(package.path_valid?(1)).to eq(false) }
      end

      context 'with major version 2' do
        it('returns true') { expect(package.path_valid?(2)).to eq(true) }
      end
    end
  end

  describe '#gomod_valid?' do
    let_it_be(:package) { create(:go_module) }

    context 'with good gomod' do
      it('returns true') { expect(package.gomod_valid?("module #{package.name}")).to eq(true) }
    end

    context 'with bad gomod' do
      it('returns false') { expect(package.gomod_valid?("module #{package.name}/v2")).to eq(false) }
    end

    context 'with empty gomod' do
      it('returns false') { expect(package.gomod_valid?("")).to eq(false) }
    end
  end
end
