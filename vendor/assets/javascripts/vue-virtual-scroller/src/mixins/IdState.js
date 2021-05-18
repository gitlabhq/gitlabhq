import Vue from 'vue'

export default function ({
  idProp = vm => vm.item.id,
} = {}) {
  const store = {}
  const vm = new Vue({
    data () {
      return {
        store,
      }
    },
  })

  // @vue/component
  return {
    data () {
      return {
        idState: null,
      }
    },

    created () {
      this.$_id = null
      if (typeof idProp === 'function') {
        this.$_getId = () => idProp.call(this, this)
      } else {
        this.$_getId = () => this[idProp]
      }
      this.$watch(this.$_getId, {
        handler (value) {
          this.$nextTick(() => {
            this.$_id = value
          })
        },
        immediate: true,
      })
      this.$_updateIdState()
    },

    beforeUpdate () {
      this.$_updateIdState()
    },

    methods: {
      /**
       * Initialize an idState
       * @param {number|string} id Unique id for the data
       */
      $_idStateInit (id) {
        const factory = this.$options.idState
        if (typeof factory === 'function') {
          const data = factory.call(this, this)
          vm.$set(store, id, data)
          this.$_id = id
          return data
        } else {
          throw new Error('[mixin IdState] Missing `idState` function on component definition.')
        }
      },

      /**
       * Ensure idState is created and up-to-date
       */
      $_updateIdState () {
        const id = this.$_getId()
        if (id == null) {
          console.warn(`No id found for IdState with idProp: '${idProp}'.`)
        }
        if (id !== this.$_id) {
          if (!store[id]) {
            this.$_idStateInit(id)
          }
          this.idState = store[id]
        }
      },
    },
  }
}
