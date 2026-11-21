export const PRODUCTS = Object.freeze([
  { id: 'EL-101', name: '无线蓝牙耳机', category: '数码', price: 129, description: '轻巧的入耳设计，适合通勤和学习。' },
  { id: 'DS-102', name: '方格笔记本', category: '文具', price: 19.9, description: '细方格内页，方便整理笔记。' },
  { id: 'EL-103', name: '折叠桌面支架', category: '数码', price: 39.9, description: '可折叠收纳，方便桌面查看手机。' },
  { id: 'LT-104', name: '随行保温杯', category: '日用', price: 69, description: '旋盖式杯口，适合日常出行。' },
  { id: 'DS-105', name: '抽绳帆布笔袋', category: '文具', price: 29.9, description: '可放入多支笔和小尺子。' }
])
export function filterProducts(items, query) {
  const keyword = String(query).trim().toLowerCase()
  return items.filter(item => [item.name, item.category, item.id]
    .some(value => value.toLowerCase().includes(keyword)))
}
export function findProduct(id) { return PRODUCTS.find(item => item.id === id) }
export function formatPrice(value) { return `¥${value.toFixed(2)}` }
