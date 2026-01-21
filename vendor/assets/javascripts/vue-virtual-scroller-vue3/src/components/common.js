export const props = {
  items: {
    type: Array,
    required: true,
  },

  keyField: {
    type: String,
    default: 'id',
  },

  direction: {
    type: String,
    default: 'vertical',
    validator: value => ['vertical', 'horizontal'].includes(value),
  },

  listTag: {
    type: String,
    default: 'div',
  },

  itemTag: {
    type: String,
    default: 'div',
  },
}

export function simpleArray() {
  return this.items.length && typeof this.items[0] !== 'object'
}
