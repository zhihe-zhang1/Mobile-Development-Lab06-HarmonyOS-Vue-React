import { PRODUCTS } from './catalog.js'

// 用本地异步服务模拟真实接口，三种状态都能离线复现。
export async function loadProducts(mode = 'success') {
  await new Promise(resolve => setTimeout(resolve, 650))
  if (mode === 'error') throw new Error('模拟接口请求失败，请重试。')
  return mode === 'empty' ? [] : PRODUCTS.map(item => ({ ...item }))
}
