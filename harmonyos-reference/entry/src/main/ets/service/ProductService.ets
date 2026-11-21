import { HttpClient } from './HttpClient';
import { LoadMode, Product, validatedProduct } from '../model/Product';

interface RemoteProduct {
  id: number;
  title: string;
  category: string;
  price: number;
  stock: number;
  description: string;
}
interface RemoteResponse { products: RemoteProduct[]; }

const SAMPLES: Product[] = [
  { id: 'EL-101', name: '无线蓝牙耳机', category: '数码', price: 129.00, currency: 'CNY',
    stock: 18, description: '轻巧的入耳设计，适合通勤、学习和日常听歌。' },
  { id: 'DS-102', name: '方格笔记本', category: '文具', price: 19.90, currency: 'CNY',
    stock: 42, description: '细方格内页，适合课堂笔记和日程整理。' },
  { id: 'EL-103', name: '折叠桌面支架', category: '数码', price: 39.90, currency: 'CNY',
    stock: 24, description: '可折叠收纳，方便桌面查看手机。' },
  { id: 'LT-104', name: '随行保温杯', category: '日用', price: 69.00, currency: 'CNY',
    stock: 31, description: '旋盖式随行杯，适合上课和通勤。' },
  { id: 'DS-105', name: '抽绳帆布笔袋', category: '文具', price: 29.90, currency: 'CNY',
    stock: 26, description: '可收纳中性笔、橡皮和便携小尺。' }
];

function demoDelay(): Promise<void> {
  return new Promise<void>((resolve: () => void) => {
    setTimeout(resolve, 1500);
  });
}

export class ProductService {
  static async list(mode: LoadMode): Promise<Product[]> {
    // 三种演示模式明确标识为本地测试，不冒充真实的 HTTP 返回。
    if (mode !== LoadMode.Network) {
      await demoDelay();
      if (mode === LoadMode.Empty) { return []; }
      if (mode === LoadMode.Failure) { throw new Error('模拟网络连接失败（测试模式）'); }
      return SAMPLES.slice();
    }
    const text = await HttpClient.get('/products?limit=12');
    let parsed: RemoteResponse;
    try {
      parsed = JSON.parse(text) as RemoteResponse;
    } catch (_) {
      throw new Error('接口数据不是合法 JSON');
    }
    if (parsed === undefined || parsed === null || !Array.isArray(parsed.products)) {
      throw new Error('接口没有返回商品列表');
    }
    const result: Product[] = [];
    for (const value of parsed.products) {
      if (typeof value.id !== 'number' || !Number.isInteger(value.id) ||
        typeof value.title !== 'string' || typeof value.category !== 'string' ||
        typeof value.price !== 'number' || typeof value.stock !== 'number' ||
        typeof value.description !== 'string') {
        throw new Error('接口数据字段格式错误');
      }
      const item: Product = {
        id: 'API-' + value.id, name: value.title, category: value.category,
        price: value.price, currency: 'USD', stock: value.stock, description: value.description
      };
      if (!validatedProduct(item)) { throw new Error('商品数据校验失败'); }
      result.push(item);
    }
    return result;
  }
}
