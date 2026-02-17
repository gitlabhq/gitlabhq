<template>
  <RecycleScroller
    ref="scroller"
    :items="itemsWithSize"
    :min-item-size="minItemSize"
    :direction="direction"
    key-field="id"
    :list-tag="listTag"
    :item-tag="itemTag"
    v-bind="$attrs"
    @resize="onScrollerResize"
    @visible="onScrollerVisible"
  >
    <template #default="{ item: itemWithSize, index, active }">
      <slot
        v-bind="{
          item: itemWithSize.item,
          index,
          active,
          itemWithSize
        }"
      />
    </template>
    <template
      v-if="$slots.before"
      #before
    >
      <slot name="before" />
    </template>
    <template
      v-if="$slots.after"
      #after
    >
      <slot name="after" />
    </template>
    <template #empty>
      <slot name="empty" />
    </template>
  </RecycleScroller>
</template>

<script>
import mitt from 'mitt'
import RecycleScroller from './RecycleScroller.vue'
import { props, simpleArray } from './common'

export default {
  name: 'DynamicScroller',

  components: {
    RecycleScroller,
  },

  provide () {
    if (typeof ResizeObserver !== 'undefined') {
      this.$_resizeObserver = new ResizeObserver(entries => {
        requestAnimationFrame(() => {
          if (!Array.isArray(entries)) {
            return
          }
          for (const entry of entries) {
            if (entry.target && entry.target.$_vs_onResize) {
              let width, height
              if (entry.borderBoxSize) {
                const resizeObserverSize = entry.borderBoxSize[0]
                width = resizeObserverSize.inlineSize
                height = resizeObserverSize.blockSize
              } else {
                // @TODO remove when contentRect is deprecated
                width = entry.contentRect.width
                height = entry.contentRect.height
              }
              entry.target.$_vs_onResize(entry.target.$_vs_id, width, height)
            }
          }
        })
      })
    }

    return {
      vscrollData: this.vscrollData,
      vscrollParent: this,
      vscrollResizeObserver: this.$_resizeObserver,
    }
  },

  inheritAttrs: false,

  props: {
    ...props,

    minItemSize: {
      type: [Number, String],
      required: true,
    },
  },

  emits: [
    'resize',
    'visible',
  ],

  data () {
    return {
      vscrollData: {
        active: true,
        sizes: {},
        keyField: this.keyField,
        simpleArray: false,
      },
    }
  },

  computed: {
    simpleArray,

    itemsWithSize () {
      const result = []
      const { items, keyField, simpleArray } = this
      const sizes = this.vscrollData.sizes
      const l = items.length
      for (let i = 0; i < l; i++) {
        const item = items[i]
        const id = simpleArray ? i : item[keyField]
        let size = sizes[id]
        if (typeof size === 'undefined' && !this.$_undefinedMap[id]) {
          size = 0
        }
        result.push({
          item,
          id,
          size,
        })
      }
      return result
    },
  },

  watch: {
    items () {
      this.forceUpdate()
    },

    simpleArray: {
      handler (value) {
        this.vscrollData.simpleArray = value
      },
      immediate: true,
    },

    direction (value) {
      this.forceUpdate(true)
    },

    itemsWithSize (next, prev) {
      const scrollTop = this.$el.scrollTop

      // Calculate total diff between prev and next sizes
      // over current scroll top. Then add it to scrollTop to
      // avoid jumping the contents that the user is seeing.
      let prevActiveTop = 0; let activeTop = 0
      const length = Math.min(next.length, prev.length)
      for (let i = 0; i < length; i++) {
        if (prevActiveTop >= scrollTop) {
          break
        }
        prevActiveTop += prev[i].size || this.minItemSize
        activeTop += next[i].size || this.minItemSize
      }
      const offset = activeTop - prevActiveTop

      if (offset === 0) {
        return
      }

      this.$el.scrollTop += offset
    },
  },

  beforeCreate () {
    this.$_updates = []
    this.$_undefinedSizes = 0
    this.$_undefinedMap = {}
    this.$_events = mitt()
  },

  activated () {
    this.vscrollData.active = true
  },

  deactivated () {
    this.vscrollData.active = false
  },

  unmounted () {
    this.$_events.all.clear()
  },

  methods: {
    onScrollerResize () {
      const scroller = this.$refs.scroller
      if (scroller) {
        this.forceUpdate()
      }
      this.$emit('resize')
    },

    onScrollerVisible () {
      this.$_events.emit('vscroll:update', { force: false })
      this.$emit('visible')
    },

    forceUpdate (clear = false) {
      if (clear || this.simpleArray) {
        this.vscrollData.sizes = {}
      }
      this.$_events.emit('vscroll:update', { force: true })
    },

    scrollToItem (index) {
      const scroller = this.$refs.scroller
      if (scroller) scroller.scrollToItem(index)
    },

    getItemSize (item, index = undefined) {
      const id = this.simpleArray ? (index != null ? index : this.items.indexOf(item)) : item[this.keyField]
      return this.vscrollData.sizes[id] || 0
    },

    scrollToBottom () {
      if (this.$_scrollingToBottom) return
      this.$_scrollingToBottom = true
      const el = this.$el
      // Item is inserted to the DOM
      this.$nextTick(() => {
        el.scrollTop = el.scrollHeight + 5000
        // Item sizes are computed
        const cb = () => {
          el.scrollTop = el.scrollHeight + 5000
          requestAnimationFrame(() => {
            el.scrollTop = el.scrollHeight + 5000
            if (this.$_undefinedSizes === 0) {
              this.$_scrollingToBottom = false
            } else {
              requestAnimationFrame(cb)
            }
          })
        }
        requestAnimationFrame(cb)
      })
    },
  },
}
</script>
