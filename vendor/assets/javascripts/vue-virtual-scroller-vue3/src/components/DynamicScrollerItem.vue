<script>
import { h } from 'vue'

export default {
  name: 'DynamicScrollerItem',

  inject: [
    'vscrollData',
    'vscrollParent',
    'vscrollResizeObserver',
  ],

  props: {
    // eslint-disable-next-line vue/require-prop-types
    item: {
      required: true,
    },

    watchData: {
      type: Boolean,
      default: false,
    },

    /**
     * Indicates if the view is actively used to display an item.
     */
    active: {
      type: Boolean,
      required: true,
    },

    index: {
      type: Number,
      default: undefined,
    },

    sizeDependencies: {
      type: [Array, Object],
      default: null,
    },

    emitResize: {
      type: Boolean,
      default: false,
    },

    tag: {
      type: String,
      default: 'div',
    },
  },

  emits: [
    'resize',
  ],

  computed: {
    id () {
      if (this.vscrollData.simpleArray) return this.index
      // eslint-disable-next-line no-prototype-builtins
      if (this.vscrollData.keyField in this.item) return this.item[this.vscrollData.keyField]
      throw new Error(`keyField '${this.vscrollData.keyField}' not found in your item. You should set a valid keyField prop on your Scroller`)
    },

    size () {
      return this.vscrollData.sizes[this.id] || 0
    },

    finalActive () {
      return this.active && this.vscrollData.active
    },
  },

  watch: {
    watchData: 'updateWatchData',

    id (value, oldValue) {
      this.$el.$_vs_id = this.id
      if (!this.size) {
        this.onDataUpdate()
      }

      if (this.$_sizeObserved) {
        // In case the old item had the same size, it won't trigger the ResizeObserver
        // since we are reusing the same DOM node
        const oldSize = this.vscrollData.sizes[oldValue]
        const size = this.vscrollData.sizes[value]

        if (size != null && size !== oldSize) {
          this.applySize(size)
        } else if (oldSize != null && oldSize !== size) {
          this.applySize(oldSize)
        }
      }
    },

    finalActive (value) {
      if (!this.size) {
        if (value) {
          if (!this.vscrollParent.$_undefinedMap[this.id]) {
            this.vscrollParent.$_undefinedSizes++
            this.vscrollParent.$_undefinedMap[this.id] = true
          }
        } else {
          if (this.vscrollParent.$_undefinedMap[this.id]) {
            this.vscrollParent.$_undefinedSizes--
            this.vscrollParent.$_undefinedMap[this.id] = false
          }
        }
      }

      if (this.vscrollResizeObserver) {
        if (value) {
          this.observeSize()
        } else {
          this.unobserveSize()
        }
      } else if (value && this.$_pendingVScrollUpdate === this.id) {
        this.updateSize()
      }
    },
  },

  created () {
    if (this.$isServer) return

    this.$_forceNextVScrollUpdate = null
    this.updateWatchData()

    if (!this.vscrollResizeObserver) {
      for (const k in this.sizeDependencies) {
        this.$watch(() => this.sizeDependencies[k], this.onDataUpdate)
      }

      this.vscrollParent.$_events.on('vscroll:update', this.onVscrollUpdate)
    }
  },

  mounted () {
    if (this.finalActive) {
      this.updateSize()
      this.observeSize()
    }
  },

  beforeUnmount () {
    this.vscrollParent.$_events.off('vscroll:update', this.onVscrollUpdate)
    this.unobserveSize()
  },

  methods: {
    updateSize () {
      if (this.finalActive) {
        if (this.$_pendingSizeUpdate !== this.id) {
          this.$_pendingSizeUpdate = this.id
          this.$_forceNextVScrollUpdate = null
          this.$_pendingVScrollUpdate = null
          this.computeSize(this.id)
        }
      } else {
        this.$_forceNextVScrollUpdate = this.id
      }
    },

    updateWatchData () {
      if (this.watchData && !this.vscrollResizeObserver) {
        this.$_watchData = this.$watch('item', () => {
          this.onDataUpdate()
        }, {
          deep: true,
        })
      } else if (this.$_watchData) {
        this.$_watchData()
        this.$_watchData = null
      }
    },

    onVscrollUpdate ({ force }) {
      // If not active, sechedule a size update when it becomes active
      if (!this.finalActive && force) {
        this.$_pendingVScrollUpdate = this.id
      }

      if (this.$_forceNextVScrollUpdate === this.id || force || !this.size) {
        this.updateSize()
      }
    },

    onDataUpdate () {
      this.updateSize()
    },

    computeSize (id) {
      this.$nextTick(() => {
        if (this.id === id) {
          const width = this.$el.offsetWidth
          const height = this.$el.offsetHeight
          this.applyWidthHeight(width, height)
        }
        this.$_pendingSizeUpdate = null
      })
    },

    applyWidthHeight (width, height) {
      const size = ~~(this.vscrollParent.direction === 'vertical' ? height : width)
      if (size && this.size !== size) {
        this.applySize(size)
      }
    },

    applySize (size) {
      if (this.vscrollParent.$_undefinedMap[this.id]) {
        this.vscrollParent.$_undefinedSizes--
        this.vscrollParent.$_undefinedMap[this.id] = undefined
      }
      this.vscrollData.sizes[this.id] = size
      if (this.emitResize) this.$emit('resize', this.id)
    },

    observeSize () {
      if (!this.vscrollResizeObserver) return
      if (this.$_sizeObserved) return
      this.vscrollResizeObserver.observe(this.$el)
      this.$el.$_vs_id = this.id
      this.$el.$_vs_onResize = this.onResize
      this.$_sizeObserved = true
    },

    unobserveSize () {
      if (!this.vscrollResizeObserver) return
      if (!this.$_sizeObserved) return
      this.vscrollResizeObserver.unobserve(this.$el)
      this.$el.$_vs_onResize = undefined
      this.$_sizeObserved = false
    },

    onResize (id, width, height) {
      if (this.id === id) {
        this.applyWidthHeight(width, height)
      }
    },
  },

  render () {
    return h(this.tag, this.$slots.default())
  },
}
</script>
