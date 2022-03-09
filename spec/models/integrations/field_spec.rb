# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Integrations::Field do
  subject(:field) { described_class.new(**attrs) }

  let(:attrs) { { name: nil } }

  describe '#name' do
    before do
      attrs[:name] = :foo
    end

    it 'is stringified' do
      expect(field.name).to eq 'foo'
      expect(field[:name]).to eq 'foo'
    end

    context 'when not set' do
      before do
        attrs.delete(:name)
      end

      it 'complains' do
        expect { field }.to raise_error(ArgumentError)
      end
    end
  end

  described_class::ATTRIBUTES.each do |name|
    describe "##{name}" do
      it "responds to #{name}" do
        expect(field).to be_respond_to(name)
      end

      context 'when not set' do
        before do
          attrs.delete(name)
        end

        let(:have_correct_default) do
          case name
          when :api_only
            be false
          when :type
            eq 'text'
          else
            be_nil
          end
        end

        it 'has the correct default' do
          expect(field[name]).to have_correct_default
          expect(field.send(name)).to have_correct_default
        end
      end

      context 'when set to a static value' do
        before do
          attrs[name] = :known
        end

        it 'is known' do
          expect(field[name]).to eq(:known)
          expect(field.send(name)).to eq(:known)
        end
      end

      context 'when set to a dynamic value' do
        before do
          attrs[name] = -> { Time.current }
        end

        it 'is computed' do
          start = Time.current

          travel_to(start + 1.minute) do
            expect(field[name]).to be_after(start)
            expect(field.send(name)).to be_after(start)
          end
        end
      end
    end
  end

  describe '#sensitive' do
    context 'when empty' do
      it { is_expected.not_to be_sensitive }
    end

    context 'when a password field' do
      before do
        attrs[:type] = 'password'
      end

      it { is_expected.to be_sensitive }
    end

    %w[token api_token api_key secret_key secret_sauce password passphrase].each do |name|
      context "when named #{name}" do
        before do
          attrs[:name] = name
        end

        it { is_expected.to be_sensitive }
      end
    end

    context "when named url" do
      before do
        attrs[:name] = :url
      end

      it { is_expected.not_to be_sensitive }
    end
  end
end
