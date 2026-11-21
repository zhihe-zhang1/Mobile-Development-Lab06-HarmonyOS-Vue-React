import { ref } from 'vue'
// Tab 状态和普通页面路由是两回事；进入详情不会重置选择。
export const activeTab = ref('all')
