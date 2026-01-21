<!-- Avoir re-renders of slots -->

<template>
  <component
    :is="itemTag"
    class="vue-recycle-scroller__item-view"
  >
    <slot
      :item="view.item"
      :index="view.nr.index"
      :active="view.nr.used"
    />
  </component>
</template>

<script>
export default {
  props: {
    view: Object,
    itemTag: String,
  },
}
</script>
