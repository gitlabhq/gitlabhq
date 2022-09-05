# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::EncryptIntegrationProperties, schema: 20220415124804 do
  let(:integrations) do
    table(:integrations) do |integrations|
      integrations.send :attr_encrypted, :encrypted_properties_tmp,
                        attribute: :encrypted_properties,
                        mode: :per_attribute_iv,
                        key: ::Settings.attr_encrypted_db_key_base_32,
                        algorithm: 'aes-256-gcm',
                        marshal: true,
                        marshaler: ::Gitlab::Json,
                        encode: false,
                        encode_iv: false
    end
  end

  let!(:no_properties) { integrations.create! }
  let!(:with_plaintext_1) { integrations.create!(properties: json_props(1)) }
  let!(:with_plaintext_2) { integrations.create!(properties: json_props(2)) }
  let!(:with_encrypted) do
    x = integrations.new
    x.properties = nil
    x.encrypted_properties_tmp = some_props(3)
    x.save!
    x
  end

  let(:start_id) { integrations.minimum(:id) }
  let(:end_id) { integrations.maximum(:id) }

  it 'ensures all properties are encrypted', :aggregate_failures do
    described_class.new.perform(start_id, end_id)

    props = integrations.all.to_h do |record|
      [record.id, [Gitlab::Json.parse(record.properties), record.encrypted_properties_tmp]]
    end

    expect(integrations.count).to eq(4)

    expect(props).to match(
      no_properties.id => both(be_nil),
      with_plaintext_1.id => both(eq some_props(1)),
      with_plaintext_2.id => both(eq some_props(2)),
      with_encrypted.id => match([be_nil, eq(some_props(3))])
    )
  end

  private

  def both(obj)
    match [obj, obj]
  end

  def some_props(id)
    HashWithIndifferentAccess.new({ id: id, foo: 1, bar: true, baz: %w[a string array] })
  end

  def json_props(id)
    some_props(id).to_json
  end
end
