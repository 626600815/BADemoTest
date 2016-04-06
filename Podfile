# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
# use_frameworks!
xcodeproj 'demoTest.xcodeproj'


# 去掉由pod引入的第三方库的警告，需要更新命令才生效
inhibit_all_warnings!

target 'demoTest' do

# 对系统原生的AutoLayout 的 NSLayoutConstraints类的封装，优雅的链式语法，GitHub 排名第三
pod 'Masonry', '~> 0.6.4'
# 两个都是自动布局框架
pod 'SDAutoLayout', '~> 1.31'
pod 'WHC_AutoLayoutKit', '~> 2.0.0'

# 为UI控件提供网络图片加载和缓存功能，AF已经整合了此功能，一般用AF就够了，据专业人士说：SD比AF快0.02秒，如果，同时引用AF和SD，那么AF的网络图片加载方法会被划线
pod 'SDWebImage', '~> 3.7.5'

# 为滚动控件（UIScrollView, UITableView, UICollectionView）添加头部脚部刷新UI
pod 'MJRefresh', '~> 3.1.0'

# 键盘框架
pod 'IQKeyboardManager', '~> 4.0.0'

# 自定义button框架
pod 'BAButton', '~> 1.0.1'

# 专门用于转换 Array/Dictionary -> 对象模型 主要用于JSON解析，基本都用这个框架（必会）
pod 'MJExtension', '~> 3.0.10'

# GitHub 排名第一的网络操作框架，底层使用NSURLSession+NSOperation(多线程)
pod 'AFNetworking', '~> 3.0'

# 在屏幕中间显示 加载框 类似于安卓的toast效果
pod 'MBProgressHUD'

# 网络或本地 多张图片浏览 控制器
pod 'MWPhotoBrowser'

# 友盟分享
pod 'UMengSocial', '~> 4.4'


end

target 'demoTestTests' do

end

target 'demoTestUITests' do

end
