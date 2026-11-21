import { ref } from 'vue'
const KEY = 'lab06-vue-favorites'
function readIds() {
  try {
    const parsed = JSON.parse(localStorage.getItem(KEY) ?? '[]')
    return Array.isArray(parsed) ? parsed.filter(id => typeof id === 'string') : []
  } catch { return [] }
}
export const favorites = ref(readIds())
export function isFavorite(id) { return favorites.value.includes(id) }
export function toggleFavorite(id) {
  favorites.value = isFavorite(id)
    ? favorites.value.filter(value => value !== id)
    : [...favorites.value, id]
  try { localStorage.setItem(KEY, JSON.stringify(favorites.value)) }
  catch { /* 无存储权限时仍允许本次会话操作 */ }
}
