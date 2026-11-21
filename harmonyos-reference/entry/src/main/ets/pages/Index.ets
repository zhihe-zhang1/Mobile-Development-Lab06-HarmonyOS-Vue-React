import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ProductList } from '../components/ProductList';
import {
  Product, DetailRequest, DetailResult, DETAIL_ROUTE,
  LoadMode, LoadStatus, filterProducts
} from '../model/Product';
import { ProductService } from '../service/ProductService';
import { ProductPreferences } from '../store/ProductPreferences';

@Entry
@Component
struct Index {
  private readonly pathStack: NavPathStack = new NavPathStack();
  private readonly tabs: TabsController = new TabsController();
  private initialized: boolean = false;
  private requestSequence: number = 0;

  @State private selectedTab: number = 0;
  @State private mode: LoadMode = LoadMode.Network;
  @State private status: LoadStatus = LoadStatus.Loading;
  @State private products: Product[] = [];
  @State private cache: Product[] = [];
  @State private favorites: string[] = [];
  @State private keyword: string = '';
  @State private errorText: string = '';
  @State private origin: string = '远程接口';
  @State private storeNotice: string = '';
  @State private lastAction: string = '';

  aboutToAppear(): void {
    if (this.initialized) { return; }
    this.initialized = true;
    this.startup();
  }

  private appContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private async startup(): Promise<void> {
    try {
      const saved = await ProductPreferences.load(this.appContext());
      this.favorites = saved.favorites;
      this.cache = saved.cached;
      this.storeNotice = '已恢复 ' + saved.favorites.length + ' 件收藏；离线缓存 ' + saved.cached.length + ' 件';
    } catch (error) {
      this.storeNotice = '本地存储读取失败，本次仍可正常浏览';
      hilog.warn(0, 'Lab05', 'Preferences 初始化失败');
    }
    // 默认使用本地示例展示功能，真实请求由“真实网络”按钮显式触发。
    await this.load(LoadMode.Sample);
  }

  private async load(nextMode: LoadMode): Promise<void> {
    // 序号保证频繁切换模式时，旧请求不会覆盖新请求的页面状态。
    const sequence = ++this.requestSequence;
    this.mode = nextMode;
    this.status = LoadStatus.Loading;
    this.errorText = '';
    this.lastAction = '';
    try {
      const items = await ProductService.list(nextMode);
      if (sequence !== this.requestSequence) { return; }
      this.products = items;
      this.origin = nextMode === LoadMode.Network ? '实时接口' : '本地演示数据';
      this.status = items.length === 0 ? LoadStatus.Empty : LoadStatus.Success;
      if (items.length > 0) {
        // 合并新旧商品快照，确保重启后能查到此前收藏的示例商品。
        const merged: Product[] = items.concat(this.cache.filter((cached: Product): boolean =>
          !items.some((current: Product): boolean => current.id === cached.id))).slice(0, 80);
        this.cache = merged;
        try {
          await ProductPreferences.saveProducts(this.appContext(), merged);
          this.storeNotice = '商品缓存已写入 Preferences（重启可恢复）';
        } catch (_) {
          this.storeNotice = '商品已显示，但离线缓存保存失败';
        }
      }
    } catch (error) {
      if (sequence !== this.requestSequence) { return; }
      this.products = [];
      this.status = LoadStatus.Failure;
      this.errorText = error instanceof Error ? error.message : '未知网络异常';
      hilog.warn(0, 'Lab05', '商品列表请求失败');
    }
  }

  private showCache(): void {
    if (this.cache.length === 0) { return; }
    ++this.requestSequence;
    this.products = this.cache.slice();
    this.status = LoadStatus.Success;
    this.origin = 'Preferences 离线缓存';
    this.errorText = '';
  }

  private visibleProducts(): Product[] {
    return filterProducts(this.products, this.keyword);
  }

  private savedProducts(): Product[] {
    const all: Product[] = this.products.concat(this.cache.filter((cached: Product): boolean =>
      !this.products.some((current: Product): boolean => current.id === cached.id)));
    return all.filter((item: Product): boolean => this.favorites.includes(item.id));
  }

  private openDetail(item: Product): void {
    if (this.pathStack.size() > 0) { return; }
    const pool = this.selectedTab === 0 ? this.visibleProducts() : this.savedProducts();
    if (!pool.some((entry: Product): boolean => entry.id === item.id)) { return; }
    // 普通页路由：传商品 id；pop 后由回调接收收藏结果。
    const args = new DetailRequest(item.id, this.favorites.includes(item.id), item);
    this.pathStack.pushPathByName(DETAIL_ROUTE, args, (info: PopInfo): void => {
      const result = info.result as DetailResult | undefined;
      if (!result || result.id !== item.id || typeof result.favorite !== 'boolean') { return; }
      this.saveFavorite(result);
    });
  }

  private async saveFavorite(result: DetailResult): Promise<void> {
    const next = this.favorites.filter((id: string): boolean => id !== result.id);
    if (result.favorite) { next.push(result.id); }
    try {
      // 等待 flush 成功后再报告“已保存”，避免误导用户。
      await ProductPreferences.saveFavorites(this.appContext(), next);
      this.favorites = next;
      this.lastAction = result.id + (result.favorite ? ' 已收藏并持久化' : ' 已取消收藏并持久化');
      this.storeNotice = '收藏变更已写入 Preferences，重启仍在';
    } catch (_) {
      this.lastAction = '收藏写入失败，请重试';
      hilog.warn(0, 'Lab05', '收藏持久化失败');
    }
  }

  @Builder
  private header() {
    Column({ space: 6 }) {
      Text('LAB 05 · ARKTS').fontSize(11).fontColor('#C2DFCE').letterSpacing(2);
      Text('网络请求与本地存储').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#FFFFFF');
      Text('真实请求 / 异步状态 / Preferences 持久化').fontSize(12).fontColor('#E0EFE6');
    }.width('100%').alignItems(HorizontalAlign.Start)
      .padding(18).backgroundColor('#245643').borderRadius(18);
  }

  @Builder
  private dataButtons() {
    Column({ space: 8 }) {
      Text('数据来源与状态测试').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1E3229');
      Row({ space: 6 }) {
        Button('真实网络').onClick((): void => { this.load(LoadMode.Network); });
        Button('示例数据').onClick((): void => { this.load(LoadMode.Sample); });
      }.width('100%');
      Row({ space: 6 }) {
        Button('空数据演示').onClick((): void => { this.load(LoadMode.Empty); });
        Button('失败演示').onClick((): void => { this.load(LoadMode.Failure); });
      }.width('100%');
      Text('空数据和失败是明确标注的本地测试；真实网络使用 HTTPS 公共商品接口。')
        .fontSize(11).fontColor('#60746A');
    }.width('100%').alignItems(HorizontalAlign.Start)
      .padding(12).backgroundColor('#FFFFFF').borderRadius(14);
  }

  @Builder
  private statusPanel() {
    if (this.status === LoadStatus.Loading) {
      Column({ space: 10 }) {
        LoadingProgress().width(34).height(34).color('#245643');
        Text('请求中 · Loading').fontSize(17).fontWeight(FontWeight.Bold);
        Text('正在异步获取商品列表…').fontSize(13).fontColor('#60746A');
      }.width('100%').padding(30).backgroundColor('#FFFFFF').borderRadius(15);
    } else if (this.status === LoadStatus.Empty) {
      Column({ space: 8 }) {
        Text('空数据 · Empty').fontSize(18).fontWeight(FontWeight.Bold);
        Text('接口没有可显示的商品。').fontSize(13).fontColor('#60746A');
        Button('重新请求').onClick((): void => { this.load(LoadMode.Network); });
      }.width('100%').padding(25).backgroundColor('#FFFFFF').borderRadius(15);
    } else if (this.status === LoadStatus.Failure) {
      Column({ space: 8 }) {
        Text('网络失败 · Error').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#B44B37');
        Text(this.errorText).fontSize(13).fontColor('#60746A');
        Button('重试真实请求').onClick((): void => { this.load(LoadMode.Network); });
        if (this.cache.length > 0) {
          Button('查看上次成功缓存（' + this.cache.length + '）')
            .onClick((): void => { this.showCache(); });
        }
      }.width('100%').padding(22).backgroundColor('#FFFFFF').borderRadius(15);
    } else {
      Column({ space: 10 }) {
        Row() {
          Text('成功 · Success').fontSize(15).fontWeight(FontWeight.Bold).fontColor('#245643');
          Text(this.origin).fontSize(11).fontColor('#60746A');
        }.width('100%').justifyContent(FlexAlign.SpaceBetween);
        TextInput({ text: this.keyword, placeholder: '搜索商品名称、编号或分类' })
          .height(42).backgroundColor('#F2F6F1')
          .onChange((text: string): void => { this.keyword = text; });
        Text('列表：' + this.visibleProducts().length + ' 件')
          .fontSize(13).fontColor('#60746A');
        if (this.visibleProducts().length === 0) {
          Text('搜索无结果，请尝试其他关键词。').fontColor('#60746A').padding(12);
        } else {
          ProductList({
            items: this.visibleProducts(), favorites: this.favorites,
            onSelect: (item: Product): void => { this.openDetail(item); }
          });
        }
      }.width('100%');
    }
  }

  @Builder
  private catalogTab() {
    Scroll() {
      Column({ space: 13 }) {
        this.header();
        this.dataButtons();
        this.statusPanel();
        if (this.lastAction.length > 0) {
          Text(this.lastAction).fontColor('#245643').fontSize(13);
        }
        Text(this.storeNotice).fontSize(12).fontColor('#60746A');
        Text('仅持久化商品列表与收藏 ID；不记录密码、Token 或隐私字段。')
          .fontSize(11).fontColor('#60746A');
      }.padding(16).width('100%');
    }.width('100%').height('100%').scrollBar(BarState.Off);
  }

  @Builder
  private favoritesTab() {
    Scroll() {
      Column({ space: 13 }) {
        this.header();
        Text('我的收藏 · ' + this.favorites.length + ' 件')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1E3229');
        Text('收藏 ID 通过 Preferences.put + flush 保存；关闭再打开仍能恢复。')
          .fontSize(12).fontColor('#60746A');
        if (this.savedProducts().length === 0) {
          Text('当前数据源中暂无可显示的收藏商品。')
            .width('100%').padding(20).fontColor('#60746A')
            .backgroundColor('#FFFFFF').borderRadius(13);
        } else {
          ProductList({ items: this.savedProducts(), favorites: this.favorites,
            onSelect: (item: Product): void => { this.openDetail(item); }
          });
        }
        Button('返回商品列表').backgroundColor('#245643')
          .onClick((): void => { this.tabs.changeIndex(0); });
        Text(this.storeNotice).fontSize(12).fontColor('#60746A');
      }.width('100%').padding(16);
    }.width('100%').height('100%').scrollBar(BarState.Off);
  }

  build() {
    Navigation(this.pathStack) {
      Tabs({ barPosition: BarPosition.End, index: this.selectedTab, controller: this.tabs }) {
        TabContent() { this.catalogTab(); }.tabBar('商品');
        TabContent() { this.favoritesTab(); }.tabBar('收藏');
      }.width('100%').height('100%').barHeight(56)
        .barBackgroundColor('#FFFFFF').scrollable(false)
        .onChange((index: number): void => { this.selectedTab = index; });
    }.width('100%').height('100%').hideTitleBar(true)
      .mode(NavigationMode.Stack).backgroundColor('#F4F7F2');
  }
}
