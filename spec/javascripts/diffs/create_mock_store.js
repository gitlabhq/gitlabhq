import Vue from 'vue';
import Vuex from 'vuex';
import diffsModule from '~/diffs/store/modules';
import notesModule from '~/notes/stores/modules';
import mockVuexModule from 'spec/helpers/mock_vuex_module';

Vue.use(Vuex);

export default function createDiffsStore() {
  return new Vuex.Store(mockVuexModule({
    modules: {
      diffs: diffsModule,
      notes: notesModule,
    },
  }));
}
