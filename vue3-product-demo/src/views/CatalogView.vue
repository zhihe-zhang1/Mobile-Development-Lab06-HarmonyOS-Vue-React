<script setup>
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { loadProducts } from '../shared/productService.js'
import { filterProducts, formatPrice } from '../shared/catalog.js'
import { activeTab } from '../stores/tabs.js'
import { favorites, isFavorite, toggleFavorite } from '../stores/favorites.js'

const router = useRouter()
const query = ref('')
const mode = ref('success')
const retry = ref(0)
const state = ref('loading')
const items = ref([])
const errorText = ref('')
let requestId = 0

// watch 对应 ArkTS 的状态变更触发异步请求；请求编号避免旧结果覆盖新结果。
watch([mode, retry], async () => {
  const current = ++requestId
  state.value = 'loading'
  errorText.value = ''
  try {
    const result = await loadProducts(mode.value)
    if (current !== requestId) return
    items.value = result
    state.value = result.length ? 'success' : 'empty'
  } catch (error) {
    if (current !== requestId) return
    items.value = []
    errorText.value = error instanceof Error ? error.message : '未知错误'
    state.value = 'error'
  }
}, { immediate: true })

const shown = computed(() => filterProducts(
  activeTab.value === 'all' ? items.value : items.value.filter(p => isFavorite(p.id)),
  query.value
))
const favoriteCount = computed(() => favorites.value.length)
function selectMode(value) {
  if (mode.value === value) retry.value++
  else mode.value = value
}
function openDetail(id) { router.push({ name: 'detail', params: { id } }) }
</script>

<template>
  <section class="controls panel">
    <h2>数据与状态测试</h2>
    <div class="actions">
      <button @click="selectMode('success')">加载商品</button>
      <button @click="selectMode('empty')">空数据</button>
      <button @click="selectMode('error')">失败模拟</button>
    </div>
    <p class="hint">所有模式使用 Promise + async/await，不依赖外网。</p>
  </section>

  <nav class="tabs" aria-label="商品分类页签">
    <button :class="{ selected: activeTab === 'all' }" @click="activeTab = 'all'">商品</button>
    <button :class="{ selected: activeTab === 'favorites' }" @click="activeTab = 'favorites'">
      收藏（{{ favoriteCount }}）
    </button>
  </nav>

  <section v-if="state === 'loading'" class="panel status" role="status">
    <span class="spinner" aria-hidden="true"></span><h2>请求中 · Loading</h2>
    <p>正在异步获取商品数据…</p>
  </section>
  <section v-else-if="state === 'empty'" class="panel status">
    <h2>空数据 · Empty</h2><p>接口返回了空列表。</p>
    <button @click="selectMode('success')">加载示例商品</button>
  </section>
  <section v-else-if="state === 'error'" class="panel status" role="alert">
    <h2 class="error">网络失败 · Error</h2><p>{{ errorText }}</p>
    <button @click="selectMode('success')">重试加载</button>
  </section>
  <section v-else>
    <label class="search-label" for="search">商品搜索</label>
    <input id="search" v-model="query" placeholder="搜索名称、分类或编号" />
    <p class="count">当前显示 {{ shown.length }} 件</p>
    <div v-if="shown.length === 0" class="panel status">没有匹配的商品。</div>
    <div v-for="item in shown" :key="item.id" class="product panel">
      <button class="item-main" @click="openDetail(item.id)">
        <strong>{{ item.name }}</strong>
        <small>{{ item.category }} · {{ item.id }}</small>
      </button>
      <div class="item-side"><b>{{ formatPrice(item.price) }}</b>
        <button class="outline" @click="toggleFavorite(item.id)">
          {{ isFavorite(item.id) ? '取消收藏' : '收藏' }}
        </button>
      </div>
    </div>
  </section>
</template>
