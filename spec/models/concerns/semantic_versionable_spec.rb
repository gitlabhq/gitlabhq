# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SemanticVersionable, feature_category: :mlops do
  using RSpec::Parameterized::TableSyntax

  before do
    model_class.reset_column_information
  end

  before_all do
    ActiveRecord::Schema.define do |_t|
      create_table :_test_semantic_versions, force: true do |t|
        t.integer :semver_major
        t.integer :semver_minor
        t.integer :semver_patch
        t.string :semver_prerelease
      end
    end
  end

  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      include SemanticVersionable

      self.table_name = '_test_semantic_versions'
    end
  end

  let(:model_instance) { model_class.new(semver: semver) }

  describe '#semver=' do
    where(:semver, :major, :minor, :patch, :prerelease) do
      '1'             | nil | nil | nil | nil
      '1.2'           | nil | nil | nil | nil
      '1.2.3'         | 1   | 2   | 3   | nil
      '1.2.3-beta'    | 1   | 2   | 3   | 'beta'
      '1.2.3.beta'    | nil | nil | nil | nil
    end

    with_them do
      it do
        expect(model_instance.semver_major).to be major
        expect(model_instance.semver_minor).to be minor
        expect(model_instance.semver_patch).to be patch
        expect(model_instance.semver_prerelease).to eq prerelease
      end
    end

    context 'with a prefix' do
      before do
        ActiveRecord::Schema.define do
          add_column :_test_semantic_versions, :semver_prefixed, :boolean
        end
      end

      where(:semver, :major, :minor, :patch, :prerelease, :prefixed) do
        'v1.2.3'         | 1 | 2 | 3 | nil    | true
        'v1.2.3-beta'    | 1 | 2 | 3 | 'beta' | true
      end

      with_them do
        it do
          expect(model_instance.semver_major).to be major
          expect(model_instance.semver_minor).to be minor
          expect(model_instance.semver_patch).to be patch
          expect(model_instance.semver_prerelease).to eq prerelease
          expect(model_instance.semver_prefixed).to eq prefixed
        end
      end
    end
  end

  describe '#semver' do
    let(:model_instance) { model_class.new(semver: semver_input) }

    where(:semver_input, :semver_value) do
      '1'             | ''
      '1.2'           | ''
      '1.2.3'         | '1.2.3'
      '1.2.3-beta'    | '1.2.3-beta'
      '1.2.3.beta'    | ''
    end

    with_them do
      it do
        expect(model_instance.semver.to_s).to eq semver_value
      end
    end

    context 'with a prefix' do
      before do
        ActiveRecord::Schema.define do
          add_column :_test_semantic_versions, :semver_prefixed, :boolean
        end
      end

      where(:semver_input, :semver_value) do
        'v1.2.3'         | 'v1.2.3'
        'v1.2.3-beta'    | 'v1.2.3-beta'
      end

      with_them do
        it do
          expect(model_instance.semver.to_s).to eq semver_value
        end
      end
    end
  end

  describe 'scopes' do
    let(:first_release) { model_class.create!(semver: '1.0.1') }
    let(:second_release) { model_class.create!(semver: '3.0.1') }
    let(:patch) { model_class.create!(semver: 'v2.0.1') }
    let(:first_beta) { model_class.create!(semver: '1.0.1-beta') }
    let(:first_alpha) { model_class.create!(semver: '1.0.1-alpha') }
    let(:second_rc) { model_class.create!(semver: '3.0.1-rc') }
    let(:first_beta2) { model_class.create!(semver: '1.0.1-beta2') }
    let(:first_beta1) { model_class.create!(semver: '1.0.1-beta1') }
    let(:first_beta10) { model_class.create!(semver: '1.0.1-beta10') }
    let(:first_beta12) { model_class.create!(semver: '1.0.1-beta.12') }
    let(:first_alpha2) { model_class.create!(semver: '1.0.1-alpha2') }
    let(:first_alpha1) { model_class.create!(semver: '1.0.1-alpha1') }
    let(:first_alpha10) { model_class.create!(semver: '1.0.1-alpha10') }
    let(:first_alpha_dot_10) { model_class.create!(semver: '1.0.1-alpha.10') }
    let(:prerelease) { model_class.create!(semver: '1.0.1-0a3f617f4303ed7b10dc603243452c5fb1d8e69b') }

    describe '.order_by_semantic_version_asc' do
      it 'orders the versions by semantic order ascending' do
        expect(model_class.order_by_semantic_version_asc).to eq([first_release, patch, second_release])
      end
    end

    describe '.order_by_semantic_version_desc' do
      it 'orders the versions by semantic order descending' do
        expect(model_class.order_by_semantic_version_desc).to eq([second_release, patch, first_release])
      end

      context 'with prerelease versions' do
        before do
          [first_release, second_release, patch, first_beta, first_beta1, first_beta2, first_beta10,
            first_beta12, first_alpha, first_alpha1, first_alpha2, first_alpha10, first_alpha_dot_10,
            second_rc, prerelease].each(&:reload)
        end

        it 'orders release versions before prerelease versions' do
          versions = model_class.order_by_semantic_version_desc.to_a

          expect(versions.index(first_release)).to be < versions.index(first_beta)
          expect(versions.index(first_release)).to be < versions.index(first_alpha)
          expect(versions.index(second_release)).to be < versions.index(second_rc)
        end

        it 'orders prerelease versions in descending order' do
          versions = model_class.order_by_semantic_version_desc.to_a

          expect(versions.index(first_beta)).to be < versions.index(first_alpha)
        end

        it 'returns the correct complete ordering' do
          expected_order = [
            second_release,       # 3.0.1
            second_rc,            # 3.0.1-rc
            patch,                # v2.0.1
            first_release,        # 1.0.1
            first_beta12,         # 1.0.1-beta.12
            first_beta10,         # 1.0.1-beta10
            first_beta2,          # 1.0.1-beta2
            first_beta1,          # 1.0.1-beta1
            first_beta,           # 1.0.1-beta
            first_alpha_dot_10,   # 1.0.1-alpha.10
            first_alpha10,        # 1.0.1-alpha10
            first_alpha2,         # 1.0.1-alpha2
            first_alpha1,         # 1.0.1-alpha1
            first_alpha,          # 1.0.1-alpha
            prerelease            # 1.0.1-0a3f617f4303ed7b10dc603243452c5fb1d8e69b
          ]

          expect(model_class.order_by_semantic_version_desc).to eq(expected_order)
        end
      end
    end
  end
end
