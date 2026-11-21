import { PRODUCTS } from './catalog.js'
// 同题异构：与 Vue 版本完全一致的异步请求边界。
export async function loadProducts(mode = 'success') {
  await new Promise(resolve => setTimeout(resolve, 650))
  if (mode === 'error') throw new Error('模拟接口请求失败，请重试。')
  return mode === 'empty' ? [] : PRODUCTS.map(item => ({ ...item }))
}
