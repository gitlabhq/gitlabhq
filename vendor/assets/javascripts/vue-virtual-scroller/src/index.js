/**
 * See https://gitlab.com/gitlab-org/gitlab/-/issues/331267 for more information on this vendored
 * dependency
 */

import config from './config'

import RecycleScroller from './components/RecycleScroller.vue'
import DynamicScroller from './components/DynamicScroller.vue'
import DynamicScrollerItem from './components/DynamicScrollerItem.vue'

export { default as IdState } from './mixins/IdState'

export {
  RecycleScroller,
  DynamicScroller,
  DynamicScrollerItem,
}

function registerComponents (Vue, prefix) {
  Vue.component(`${prefix}recycle-scroller`, RecycleScroller)
  Vue.component(`${prefix}RecycleScroller`, RecycleScroller)
  Vue.component(`${prefix}dynamic-scroller`, DynamicScroller)
  Vue.component(`${prefix}DynamicScroller`, DynamicScroller)
  Vue.component(`${prefix}dynamic-scroller-item`, DynamicScrollerItem)
  Vue.component(`${prefix}DynamicScrollerItem`, DynamicScrollerItem)
}

const plugin = {
  // eslint-disable-next-line no-undef
  install (Vue, options) {
    const finalOptions = Object.assign({}, {
      installComponents: true,
      componentsPrefix: '',
    }, options)

    for (const key in finalOptions) {
      if (typeof finalOptions[key] !== 'undefined') {
        config[key] = finalOptions[key]
      }
    }

    if (finalOptions.installComponents) {
      registerComponents(Vue, finalOptions.componentsPrefix)
    }
  },
}

export default plugin

// Auto-install
let GlobalVue = null
if (typeof window !== 'undefined') {
  GlobalVue = window.Vue
} else if (typeof global !== 'undefined') {
  GlobalVue = global.Vue
}
if (GlobalVue) {
  GlobalVue.use(plugin)
}
