import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import { HashRouter, Route, Routes, useNavigate, useParams } from 'react-router-dom'
import { PRODUCTS, findProduct, filterProducts, formatPrice } from './shared/catalog.js'
import { loadProducts } from './shared/productService.js'

const KEY = 'lab06-react-favorites'
const FavoritesContext = createContext(null)
function readFavorites() {
  try {
    const result = JSON.parse(localStorage.getItem(KEY) ?? '[]')
    return Array.isArray(result) ? result.filter(id => typeof id === 'string') : []
  } catch { return [] }
}
function FavoritesProvider({ children }) {
  const [ids, setIds] = useState(readFavorites)
  useEffect(() => {
    try { localStorage.setItem(KEY, JSON.stringify(ids)) }
    catch { /* 浏览器禁用本地存储时，仅维持内存状态 */ }
  }, [ids])
  const toggle = useCallback(id => {
    setIds(current => current.includes(id)
      ? current.filter(item => item !== id) : [...current, id])
  }, [])
  const value = useMemo(() => ({ ids, toggle }), [ids, toggle])
  return <FavoritesContext.Provider value={value}>{children}</FavoritesContext.Provider>
}
function useFavorites() { return useContext(FavoritesContext) }

function Catalog({ tab, setTab }) {
  const navigate = useNavigate()
  const { ids, toggle } = useFavorites()
  const [query, setQuery] = useState('')
  const [mode, setMode] = useState('success')
  const [retry, setRetry] = useState(0)
  const [status, setStatus] = useState('loading')
  const [items, setItems] = useState([])
  const [errorText, setErrorText] = useState('')

  // useEffect 对应 Vue 的 watch：依赖改变重新执行，清理函数避免旧请求覆盖。
  useEffect(() => {
    let cancelled = false
    setStatus('loading')
    setErrorText('')
    async function refresh() {
      try {
        const result = await loadProducts(mode)
        if (cancelled) return
        setItems(result)
        setStatus(result.length ? 'success' : 'empty')
      } catch (error) {
        if (cancelled) return
        setItems([])
        setErrorText(error instanceof Error ? error.message : '未知错误')
        setStatus('error')
      }
    }
    refresh()
    return () => { cancelled = true }
  }, [mode, retry])

  const shown = useMemo(() => {
    const subset = tab === 'all' ? items : items.filter(p => ids.includes(p.id))
    return filterProducts(subset, query)
  }, [items, tab, ids, query])
  function selectMode(value) {
    if (mode === value) setRetry(count => count + 1)
    else setMode(value)
  }

  return <>
    <section className="controls panel">
      <h2>数据与状态测试</h2>
      <div className="actions">
        <button onClick={() => selectMode('success')}>加载商品</button>
        <button onClick={() => selectMode('empty')}>空数据</button>
        <button onClick={() => selectMode('error')}>失败模拟</button>
      </div>
      <p className="hint">所有模式使用 Promise + async/await，不依赖外网。</p>
    </section>
    <nav className="tabs" aria-label="商品分类页签">
      <button className={tab === 'all' ? 'selected' : ''} onClick={() => setTab('all')}>商品</button>
      <button className={tab === 'favorites' ? 'selected' : ''} onClick={() => setTab('favorites')}>
        收藏（{ids.length}）
      </button>
    </nav>
    {status === 'loading' ? <section className="panel status" role="status">
      <span className="spinner" aria-hidden="true"/><h2>请求中 · Loading</h2>
      <p>正在异步获取商品数据…</p>
    </section> : status === 'empty' ? <section className="panel status">
      <h2>空数据 · Empty</h2><p>接口返回了空列表。</p>
      <button onClick={() => selectMode('success')}>加载示例商品</button>
    </section> : status === 'error' ? <section className="panel status" role="alert">
      <h2 className="error">网络失败 · Error</h2><p>{errorText}</p>
      <button onClick={() => selectMode('success')}>重试加载</button>
    </section> : <section>
      <label className="search-label" htmlFor="search">商品搜索</label>
      <input id="search" value={query} onChange={e => setQuery(e.target.value)}
        placeholder="搜索名称、分类或编号"/>
      <p className="count">当前显示 {shown.length} 件</p>
      {shown.length === 0 && <div className="panel status">没有匹配的商品。</div>}
      {shown.map(item => <div key={item.id} className="product panel">
        <button className="item-main" onClick={() => navigate(`/product/${item.id}`)}>
          <strong>{item.name}</strong><small>{item.category} · {item.id}</small>
        </button>
        <div className="item-side"><b>{formatPrice(item.price)}</b>
          <button className="outline" onClick={() => toggle(item.id)}>
            {ids.includes(item.id) ? '取消收藏' : '收藏'}
          </button>
        </div>
      </div>)}
    </section>}
  </>
}

function Detail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { ids, toggle } = useFavorites()
  const product = findProduct(id)
  const goBack = () => {
    // React Router 的 useNavigate(-1) 相当于普通页返回。
    if (window.history.state?.idx > 0) navigate(-1)
    else navigate('/', { replace: true })
  }
  return product ? <section className="panel detail">
    <button className="text-button" onClick={goBack}>‹ 返回列表</button>
    <p className="eyebrow">PRODUCT / {product.id}</p>
    <h2>{product.name}</h2><p className="price">{formatPrice(product.price)}</p>
    <p>分类：{product.category}</p><p>{product.description}</p>
    <button onClick={() => toggle(product.id)}>
      {ids.includes(product.id) ? '取消收藏' : '收藏商品'}
    </button>
  </section> : <section className="panel status">
    <h2>商品不存在</h2><button onClick={goBack}>返回列表</button>
  </section>
}

export default function App() {
  // Tab 是本地组件状态，不调用路由。打开详情才使用 navigate。
  const [tab, setTab] = useState('all')
  return <FavoritesProvider><HashRouter><main className="shell">
    <header className="hero">
      <p className="eyebrow">LAB 06 · REACT</p>
      <h1>商品列表：同题异构</h1>
      <p>异步状态 / 搜索 / 收藏 / 页面路由</p>
    </header>
    <Routes>
      <Route path="/" element={<Catalog tab={tab} setTab={setTab}/>} />
      <Route path="/product/:id" element={<Detail/>}/>
      <Route path="*" element={<Catalog tab={tab} setTab={setTab}/>} />
    </Routes>
    <footer>React Hooks · React Router · localStorage</footer>
  </main></HashRouter></FavoritesProvider>
}
