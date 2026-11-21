<script setup>
import { useRoute, useRouter } from 'vue-router'
import { findProduct, formatPrice } from '../shared/catalog.js'
import { isFavorite, toggleFavorite } from '../stores/favorites.js'
const route = useRoute()
const router = useRouter()
const product = findProduct(String(route.params.id))
function goBack() {
  // 路由历史存在则返回；从外部直接打开详情时回首页。
  if (window.history.state?.back != null) router.back()
  else router.replace('/')
}
</script>
<template>
  <section class="panel detail" v-if="product">
    <button class="text-button" @click="goBack">‹ 返回列表</button>
    <p class="eyebrow">PRODUCT / {{ product.id }}</p>
    <h2>{{ product.name }}</h2>
    <p class="price">{{ formatPrice(product.price) }}</p>
    <p>分类：{{ product.category }}</p><p>{{ product.description }}</p>
    <button @click="toggleFavorite(product.id)">{{ isFavorite(product.id) ? '取消收藏' : '收藏商品' }}</button>
  </section>
  <section v-else class="panel status">
    <h2>商品不存在</h2><button @click="goBack">返回列表</button>
  </section>
</template>
