# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Maven::Upstream, type: :model, feature_category: :virtual_registry do
  using RSpec::Parameterized::TableSyntax

  subject(:upstream) { build(:virtual_registries_packages_maven_upstream) }

  it_behaves_like 'it has loose foreign keys' do
    let(:factory_name) { :virtual_registries_packages_maven_upstream }
  end

  describe 'associations' do
    it do
      is_expected.to have_many(:cache_entries)
        .class_name('VirtualRegistries::Packages::Maven::Cache::Entry')
        .inverse_of(:upstream)
    end

    it do
      is_expected.to have_one(:registry_upstream)
        .class_name('VirtualRegistries::Packages::Maven::RegistryUpstream')
        .inverse_of(:upstream)
    end

    it do
      is_expected.to have_one(:registry)
        .through(:registry_upstream)
        .class_name('VirtualRegistries::Packages::Maven::Registry')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_uniqueness_of(:encrypted_username_iv).ignoring_case_sensitivity.allow_nil }
    it { is_expected.to validate_uniqueness_of(:encrypted_password_iv).ignoring_case_sensitivity.allow_nil }
    it { is_expected.to validate_length_of(:url).is_at_most(255) }
    it { is_expected.to validate_length_of(:username).is_at_most(255) }
    it { is_expected.to validate_length_of(:password).is_at_most(255) }
    it { is_expected.to validate_numericality_of(:cache_validity_hours).only_integer.is_greater_than_or_equal_to(0) }

    context 'for url' do
      where(:url, :valid, :error_messages) do
        'http://test.maven'   | true  | nil
        'https://test.maven'  | true  | nil
        'git://test.maven'    | false | ['Url is blocked: Only allowed schemes are http, https']
        nil                   | false | ["Url can't be blank", 'Url must be a valid URL']
        ''                    | false | ["Url can't be blank", 'Url must be a valid URL']
        "http://#{'a' * 255}" | false | 'Url is too long (maximum is 255 characters)'
        'http://127.0.0.1'    | false | 'Url is blocked: Requests to localhost are not allowed'
        'maven.local'         | false | 'Url is blocked: Only allowed schemes are http, https'
        'http://192.168.1.2'  | false | 'Url is blocked: Requests to the local network are not allowed'
      end

      with_them do
        before do
          upstream.url = url
        end

        if params[:valid]
          it { expect(upstream).to be_valid }
        else
          it do
            expect(upstream).not_to be_valid
            expect(upstream.errors).to contain_exactly(*error_messages)
          end
        end
      end
    end

    context 'for credentials' do
      where(:username, :password, :valid, :error_message) do
        'user'      | 'password'   | true  | nil
        ''          | ''           | true  | nil
        ''          | nil          | true  | nil
        nil         | ''           | true  | nil
        nil         | 'password'   | false | "Username can't be blank"
        'user'      | nil          | false | "Password can't be blank"
        ''          | 'password'   | false | "Username can't be blank"
        'user'      | ''           | false | "Password can't be blank"
        ('a' * 256) | 'password'   | false | 'Username is too long (maximum is 255 characters)'
        'user'      | ('a' * 256)  | false | 'Password is too long (maximum is 255 characters)'
      end

      with_them do
        before do
          upstream.username = username
          upstream.password = password
        end

        if params[:valid]
          it { expect(upstream).to be_valid }
        else
          it do
            expect(upstream).not_to be_valid
            expect(upstream.errors).to contain_exactly(error_message)
          end
        end
      end

      context 'when url is updated' do
        where(:new_url, :new_user, :new_pwd, :expected_user, :expected_pwd) do
          'http://original_url.test' | 'test' | 'test' | 'test' | 'test'
          'http://update_url.test'   | 'test' | 'test' | 'test' | 'test'
          'http://update_url.test'   | :none  | :none  | nil    | nil
          'http://update_url.test'   | 'test' | :none  | nil    | nil
          'http://update_url.test'   | :none  | 'test' | nil    | nil
        end

        with_them do
          before do
            upstream.update!(url: 'http://original_url.test', username: 'original_user', password: 'original_pwd')
          end

          it 'resets the username and the password when necessary' do
            new_attributes = { url: new_url, username: new_user, password: new_pwd }.select { |_, v| v != :none }
            upstream.update!(new_attributes)

            expect(upstream.reload.url).to eq(new_url)
            expect(upstream.username).to eq(expected_user)
            expect(upstream.password).to eq(expected_pwd)
          end
        end
      end
    end
  end

  describe 'callbacks' do
    context 'for set_cache_validity_hours_for_maven_central' do
      %w[
        https://repo1.maven.org/maven2
        https://repo1.maven.org/maven2/
      ].each do |maven_central_url|
        context "with url set to #{maven_central_url}" do
          before do
            upstream.url = maven_central_url
          end

          it 'sets the cache validity hours to 0' do
            upstream.save!

            expect(upstream.cache_validity_hours).to eq(0)
          end
        end
      end

      context 'with url other than maven central' do
        before do
          upstream.url = 'https://test.org/maven2'
        end

        it 'sets the cache validity hours to the database default value' do
          upstream.save!

          expect(upstream.cache_validity_hours).not_to eq(0)
        end
      end

      context 'with no url' do
        before do
          upstream.url = nil
        end

        it 'does not set the cache validity hours' do
          expect(upstream).not_to receive(:set_cache_validity_hours_for_maven_central)

          expect { upstream.save! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end

  context 'for credentials persistance' do
    it 'persists and reads back credentials properly' do
      upstream.username = 'test'
      upstream.password = 'test'

      upstream.save!

      upstream_read = upstream.reload
      expect(upstream_read.username).to eq('test')
      expect(upstream_read.password).to eq('test')
    end
  end

  describe '#url_for' do
    subject { upstream.url_for(path) }

    where(:path, :expected_url) do
      'path'      | 'http://test.maven/path'
      ''          | 'http://test.maven/'
      '/path'     | 'http://test.maven/path'
      '/sub/path' | 'http://test.maven/sub/path'
    end

    with_them do
      before do
        upstream.url = 'http://test.maven/'
      end

      it { is_expected.to eq(expected_url) }
    end
  end

  describe '#headers' do
    subject { upstream.headers }

    where(:username, :password, :expected_headers) do
      'user' | 'pass' | { Authorization: 'Basic dXNlcjpwYXNz' }
      'user' | ''     | {}
      ''     | 'pass' | {}
      ''     | ''     | {}
    end

    with_them do
      before do
        upstream.username = username
        upstream.password = password
      end

      it { is_expected.to eq(expected_headers) }
    end
  end

  describe '#as_json' do
    subject { upstream.as_json }

    it { is_expected.not_to include('username', 'password') }
  end

  describe '#default_cache_entries' do
    let_it_be(:upstream) { create(:virtual_registries_packages_maven_upstream) }

    let_it_be(:default_cache_entry) do
      create(:virtual_registries_packages_maven_cache_entry, upstream: upstream)
    end

    let_it_be(:pending_destruction_cache_entry) do
      create(:virtual_registries_packages_maven_cache_entry, :pending_destruction, upstream: upstream)
    end

    subject { upstream.default_cache_entries }

    it { is_expected.to contain_exactly(default_cache_entry) }
  end

  describe '#object_storage_key_for' do
    let_it_be(:upstream) { build_stubbed(:virtual_registries_packages_maven_upstream) }

    let(:registry_id) { '555' }

    subject { upstream.object_storage_key_for(registry_id: registry_id) }

    it 'contains the expected terms' do
      is_expected.to include("virtual_registries/packages/maven/#{registry_id}/upstream/#{upstream.id}/cache/entry")
    end

    it 'does not return the same value when called twice' do
      first_value = upstream.object_storage_key_for(registry_id: registry_id)
      second_value = upstream.object_storage_key_for(registry_id: registry_id)

      expect(first_value).not_to eq(second_value)
    end
  end
end
