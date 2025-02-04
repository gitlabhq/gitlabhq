# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Pages, feature_category: :pages do
  subject(:entry) { described_class.new(config) }

  describe 'validation' do
    context 'when value given is neither a hash nor a boolean' do
      let(:config) { 'value' }

      it 'is invalid' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include('pages config should be a hash or a boolean value')
      end
    end

    context 'when value is a hash' do
      context 'when the hash is valid' do
        let(:config) { { path_prefix: 'prefix', expire_in: '1 day', publish: '/some-folder' } }

        it 'is valid' do
          expect(entry).to be_valid
          expect(entry.value).to eq({
            path_prefix: 'prefix',
            expire_in: '1 day',
            publish: '/some-folder'
          })
        end
      end

      context 'when hash contains not allowed keys' do
        let(:config) { { unknown: 'echo' } }

        it 'is invalid' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include('pages config contains unknown keys: unknown')
        end
      end

      context 'when it specifies path_prefix' do
        context 'and it is not a string' do
          let(:config) { { path_prefix: 1 } }

          it 'is invalid' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include('pages path prefix should be a string')
          end
        end
      end

      context 'when it specifies expire_in' do
        context 'and it is a duration string' do
          let(:config) { { expire_in: '1 day' } }

          it 'is valid' do
            expect(entry).to be_valid
            expect(entry.value).to eq({
              expire_in: '1 day'
            })
          end
        end

        context 'and it is never' do
          let(:config) { { expire_in: 'never' } }

          it 'is valid' do
            expect(entry).to be_valid
            expect(entry.value).to eq({
              expire_in: 'never'
            })
          end
        end

        context 'and it is nil' do
          let(:config) { { expire_in: nil } }

          it 'is valid' do
            expect(entry).to be_valid
            expect(entry.value).to eq({
              expire_in: nil
            })
          end
        end

        context 'and it is an invalid duration' do
          let(:config) { { expire_in: 'some string that cant be parsed' } }

          it 'is valid' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include('pages expire in should be a duration')
          end
        end
      end
    end
  end
end
