# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Response, feature_category: :mcp_server do
  describe '.success' do
    context 'with formatted content only' do
      it 'returns a successful response' do
        content = [{ type: 'text', text: 'Test content' }]
        result = described_class.success(content)

        expect(result).to eq({
          content: content,
          structuredContent: {},
          isError: false
        })
      end
    end

    context 'with formatted content and hash data' do
      it 'returns a successful response with structured content' do
        content = [{ type: 'text', text: 'Test content' }]
        data = { key: 'value', count: 42 }
        result = described_class.success(content, data)

        expect(result).to eq({
          content: content,
          structuredContent: data,
          isError: false
        })
      end
    end

    context 'with formatted content and array data' do
      it 'returns a successful response with structured content metadata' do
        content = [{ type: 'text', text: 'item1' }, { type: 'text', text: '2' }]
        data = [{ id: 1, name: 'item1' }, { id: 2, name: 'item2' }]
        result = described_class.success(content, data)

        expect(result).to eq({
          content: content,
          structuredContent: {
            items: data,
            metadata: {
              count: 2,
              has_more: false
            }
          },
          isError: false
        })
      end
    end

    context 'with formatted content and nil data' do
      it 'returns a successful response with empty structured content' do
        content = [{ type: 'text', text: 'Test content' }]
        result = described_class.success(content, nil)

        expect(result).to eq({
          content: content,
          structuredContent: {},
          isError: false
        })
      end
    end

    context 'with formatted content and empty array data' do
      it 'returns a successful response with empty array metadata' do
        content = [{ type: 'text', text: 'No items found' }]
        data = []
        result = described_class.success(content, data)

        expect(result).to eq({
          content: content,
          structuredContent: {
            items: [],
            metadata: {
              count: 0,
              has_more: false
            }
          },
          isError: false
        })
      end
    end

    context 'with formatted content and string data' do
      it 'returns a successful response with empty structured content' do
        content = [{ type: 'text', text: 'Test content' }]
        result = described_class.success(content, 'string data')

        expect(result).to eq({
          content: content,
          structuredContent: {},
          isError: false
        })
      end
    end
  end

  describe '.error' do
    context 'with message only' do
      it 'returns an error response' do
        result = described_class.error('Something went wrong')

        expect(result).to eq({
          content: [{ type: 'text', text: 'Something went wrong' }],
          structuredContent: {},
          isError: true
        })
      end
    end

    context 'with message and details' do
      it 'returns an error response with structured content' do
        details = { code: 404, reason: 'Not found' }
        result = described_class.error('Resource not found', details)

        expect(result).to eq({
          content: [{ type: 'text', text: 'Resource not found' }],
          structuredContent: { error: details },
          isError: true
        })
      end
    end

    context 'with symbol message' do
      it 'converts the message to string' do
        result = described_class.error(:validation_failed)

        expect(result).to eq({
          content: [{ type: 'text', text: 'validation_failed' }],
          structuredContent: {},
          isError: true
        })
      end
    end

    context 'with nil details' do
      it 'returns an error response with empty structured content' do
        result = described_class.error('Error message', nil)

        expect(result).to eq({
          content: [{ type: 'text', text: 'Error message' }],
          structuredContent: {},
          isError: true
        })
      end
    end
  end

  describe '.format_text' do
    context 'when item is a hash with a web_url' do
      it 'returns the web_url value' do
        item = { 'id' => 1, 'name' => 'Test', 'web_url' => 'https://example.com/test' }
        result = described_class.send(:format_text, item)

        expect(result).to eq('https://example.com/test')
      end
    end

    context 'when item is a hash with nil web_url' do
      it 'formats key-value pairs with humanized keys' do
        item = { 'created_at' => '2024-01-01', 'user_name' => 'john_doe', 'web_url' => nil }
        result = described_class.send(:format_text, item)

        expect(result).to eq("Created at: 2024-01-01\nUser name: john_doe\nWeb url: ")
      end
    end

    context 'when item is a hash without web_url' do
      it 'formats key-value pairs with humanized keys' do
        item = { 'created_at' => '2024-01-01', 'user_name' => 'john_doe', 'status' => 'active' }
        result = described_class.send(:format_text, item)

        expect(result).to eq("Created at: 2024-01-01\nUser name: john_doe\nStatus: active")
      end
    end

    context 'when item is an array' do
      it 'maps and formats array indices and values' do
        items = %w[first second]
        result = described_class.send(:format_text, items)

        expect(result).to eq("First: \nSecond: ")
      end
    end

    context 'when item is an array of hashes' do
      it 'formats the array indices and hash string representations' do
        items = [{ 'name' => 'First' }, { 'name' => 'Second' }]
        result = described_class.send(:format_text, items)

        expected_first = "{\"name\"=>\"first\"}:"
        expected_second = "{\"name\"=>\"second\"}:"
        expect(result).to eq("#{expected_first} \n#{expected_second} ")
      end
    end
  end

  describe '.format_content' do
    context 'when data is a hash without web_url' do
      it 'returns an array with single text content formatted as key-value pairs' do
        data = { 'title' => 'Test Title', 'description' => 'Test Description' }
        result = described_class.send(:format_content, data)

        expect(result).to eq([{
          type: 'text',
          text: "Title: Test Title\nDescription: Test Description"
        }])
      end
    end

    context 'when data is a hash with web_url' do
      it 'returns an array with the web_url as text content' do
        data = { 'id' => 1, 'web_url' => 'https://example.com/item/1' }
        result = described_class.send(:format_content, data)

        expect(result).to eq([{
          type: 'text',
          text: 'https://example.com/item/1'
        }])
      end
    end

    context 'when data is an array of hashes without web_url' do
      it 'returns an array of text content for each item' do
        data = [
          { 'id' => 1, 'title' => 'First Item' },
          { 'id' => 2, 'title' => 'Second Item' }
        ]
        result = described_class.send(:format_content, data)

        expect(result).to eq([
          { type: 'text', text: "Id: 1\nTitle: First Item" },
          { type: 'text', text: "Id: 2\nTitle: Second Item" }
        ])
      end
    end

    context 'when data is an array of hashes with web_url' do
      it 'returns an array of text content with web_url values' do
        data = [
          { 'id' => 1, 'web_url' => 'https://example.com/item/1' },
          { 'id' => 2, 'web_url' => 'https://example.com/item/2' }
        ]
        result = described_class.send(:format_content, data)

        expect(result).to eq([
          { type: 'text', text: 'https://example.com/item/1' },
          { type: 'text', text: 'https://example.com/item/2' }
        ])
      end
    end

    context 'when data is neither hash nor array' do
      it 'returns JSON representation' do
        data = 'simple string'
        result = described_class.send(:format_content, data)

        expect(result).to eq('"simple string"')
      end
    end
  end

  describe '.format_structured_content' do
    context 'when data is a hash' do
      it 'returns the hash unchanged' do
        data = { key: 'value', nested: { inner: 'data' } }
        result = described_class.send(:format_structured_content, data)

        expect(result).to eq(data)
      end
    end

    context 'when data is an array' do
      it 'returns a structured format with metadata' do
        data = [{ id: 1 }, { id: 2 }, { id: 3 }]
        result = described_class.send(:format_structured_content, data)

        expect(result).to eq({
          items: data,
          metadata: {
            count: 3,
            has_more: false
          }
        })
      end
    end

    context 'when data is an empty array' do
      it 'returns structured format with zero count' do
        data = []
        result = described_class.send(:format_structured_content, data)

        expect(result).to eq({
          items: [],
          metadata: {
            count: 0,
            has_more: false
          }
        })
      end
    end

    context 'when data is neither hash nor array' do
      it 'returns empty hash' do
        result = described_class.send(:format_structured_content, 'string')
        expect(result).to eq({})

        result = described_class.send(:format_structured_content, 123)
        expect(result).to eq({})

        result = described_class.send(:format_structured_content, nil)
        expect(result).to eq({})
      end
    end
  end
end
