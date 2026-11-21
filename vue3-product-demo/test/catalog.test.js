import test from 'node:test'
import assert from 'node:assert/strict'
import { PRODUCTS, filterProducts, findProduct, formatPrice } from '../src/shared/catalog.js'
import { loadProducts } from '../src/shared/productService.js'

test('搜索商品名称、分类、编号', () => {
  assert.equal(filterProducts(PRODUCTS, '蓝牙').length, 1)
  assert.equal(filterProducts(PRODUCTS, '文具').length, 2)
  assert.equal(filterProducts(PRODUCTS, 'EL-103')[0].name, '折叠桌面支架')
})
test('商品详情和价格格式', () => {
  assert.equal(findProduct('DS-102').name, '方格笔记本')
  assert.equal(formatPrice(19.9), '¥19.90')
})
test('异步状态返回成功/空数据/失败', async () => {
  assert.equal((await loadProducts('success')).length, PRODUCTS.length)
  assert.deepEqual(await loadProducts('empty'), [])
  await assert.rejects(loadProducts('error'), /模拟接口请求失败/)
})
