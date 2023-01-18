# frozen_string_literal: true

RSpec.shared_examples Integrations::ResetSecretFields do
  describe '#exposing_secrets_fields' do
    it 'returns an array of strings' do
      expect(integration.exposing_secrets_fields).to be_a(Array)
      expect(integration.exposing_secrets_fields).to all(be_a(String))
    end
  end

  describe '#reset_secret_fields?' do
    let(:exposing_fields) { integration.exposing_secrets_fields }

    it 'returns false if no exposing field has changed' do
      exposing_fields.each do |field|
        allow(integration).to receive("#{field}_changed?").and_return(false)
      end

      expect(integration.send(:reset_secret_fields?)).to be(false)
    end

    it 'returns true if any exposing field has changed' do
      exposing_fields.each do |field|
        allow(integration).to receive("#{field}_changed?").and_return(true)

        other_exposing_fields = exposing_fields.without(field)
        other_exposing_fields.each do |other_field|
          allow(integration).to receive("#{other_field}_changed?").and_return(false)
        end

        expect(integration.send(:reset_secret_fields?)).to be(true)
      end
    end
  end

  describe 'validation callback' do
    before do
      # Store a value in each password field
      integration.secret_fields.each do |field|
        integration.public_send("#{field}=", 'old value')
      end

      # Treat values as persisted
      integration.reset_updated_properties
      integration.instance_variable_set(:@old_data_fields, nil) if integration.supports_data_fields?
    end

    context 'when an exposing field has changed' do
      let(:exposing_field) { integration.exposing_secrets_fields.first }

      before do
        integration.public_send("#{exposing_field}=", 'new value')
      end

      it 'clears all secret fields' do
        integration.valid?

        integration.secret_fields.each do |field|
          expect(integration.public_send(field)).to be_nil
          expect(integration.properties[field]).to be_nil if integration.properties.present?
          expect(integration.data_fields[field]).to be_nil if integration.supports_data_fields?
        end
      end

      context 'when a secret field has been updated' do
        let(:secret_field) { integration.secret_fields.first }
        let(:other_secret_fields) { integration.secret_fields.without(secret_field) }
        let(:new_value) { 'new value' }

        before do
          integration.public_send("#{secret_field}=", new_value)
        end

        it 'does not clear this secret field' do
          integration.valid?

          expect(integration.public_send(secret_field)).to eq('new value')

          other_secret_fields.each do |field|
            expect(integration.public_send(field)).to be_nil
          end
        end

        context 'when a secret field has been updated with the same value' do
          let(:new_value) { 'old value' }

          it 'does not clear this secret field' do
            integration.valid?

            expect(integration.public_send(secret_field)).to eq('old value')

            other_secret_fields.each do |field|
              expect(integration.public_send(field)).to be_nil
            end
          end
        end
      end
    end

    context 'when no exposing field has changed' do
      it 'does not clear any secret fields' do
        integration.valid?

        integration.secret_fields.each do |field|
          expect(integration.public_send(field)).to eq('old value')
        end
      end
    end
  end
end
