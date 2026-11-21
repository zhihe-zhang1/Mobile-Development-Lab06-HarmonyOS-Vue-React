import { createRouter, createWebHashHistory } from 'vue-router'
import CatalogView from './views/CatalogView.vue'
import DetailView from './views/DetailView.vue'

export default createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'catalog', component: CatalogView },
    { path: '/product/:id', name: 'detail', component: DetailView },
    { path: '/:pathMatch(.*)*', redirect: '/' }
  ]
})
