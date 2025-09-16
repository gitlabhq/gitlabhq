# frozen_string_literal: true

RSpec.shared_examples 'model with redactable field' do
  context 'when reply key has the legacy format' do
    it 'redacts unsubscribe token' do
      model[field] = 'some text /sent_notifications/00000000000000000000000000000000/unsubscribe more text'

      model.save!

      expect(model[field]).to eq 'some text /sent_notifications/REDACTED/unsubscribe more text'
    end

    it 'redacts the field when saving the model before creating markdown cache' do
      model[field] = 'some text /sent_notifications/00000000000000000000000000000000/unsubscribe more text'

      model.save!

      expected = 'some text /sent_notifications/REDACTED/unsubscribe more text'
      expect(model[field]).to eq expected
      expect(model["#{field}_html"]).to eq "<p dir=\"auto\">#{expected}</p>"
    end
  end

  context 'when reply key has the partitioned format' do
    it 'redacts unsubscribe token' do
      model[field] = "some text /sent_notifications/1-#{SentNotification.reply_key}/unsubscribe more text"

      model.save!

      expect(model[field]).to eq 'some text /sent_notifications/REDACTED/unsubscribe more text'
    end

    it 'redacts the field when saving the model before creating markdown cache' do
      model[field] = "some text /sent_notifications/1-#{SentNotification.reply_key}/unsubscribe more text"

      model.save!

      expected = 'some text /sent_notifications/REDACTED/unsubscribe more text'
      expect(model[field]).to eq expected
      expect(model["#{field}_html"]).to eq "<p dir=\"auto\">#{expected}</p>"
    end
  end

  it 'ignores not hexadecimal tokens' do
    text = 'some text /sent_notifications/token/unsubscribe more text'
    model[field] = text

    model.save!

    expect(model[field]).to eq text
  end

  it 'ignores not matching texts' do
    text = 'some text /sent_notifications/.*/unsubscribe more text'
    model[field] = text

    model.save!

    expect(model[field]).to eq text
  end
end
