//
//  DemoVC25.h
//  demoTest
//
//  Created by 博爱 on 16/4/25.
//  Copyright © 2016年 博爱之家. All rights reserved.
//

#import "BAVideoPlayer.h"
#import <MediaPlayer/MediaPlayer.h>

#define BA_VideoSrcName(file) [@"BAVideoPlayer.bundle" stringByAppendingPathComponent:file]
#define BA_VideoFrameworkSrcName(file) [@"Frameworks/BAVideoPlayer.framework/BAVideoPlayer.bundle" stringByAppendingPathComponent:file]

#define BA_HalfWidth self.frame.size.width * 0.5
#define BA_HalfHeight self.frame.size.height * 0.5

// 当前设备的屏幕宽度
#define BA_SCREEN_WIDTH    [[UIScreen mainScreen] bounds].size.width
// 当前设备的屏幕高度
#define BA_SCREEN_HEIGHT   [[UIScreen mainScreen] bounds].size.height

// 上下导航栏高(全屏时上导航栏高+20)
#define BATOPHEIGHT(FullScreen) ((FullScreen==YES)?60:40)
#define BAFOOTHEIGHT 40

// 导航栏上button的宽高
#define BAButtonWidth 30
#define BAButtonHeight 30

// 导航栏隐藏前所需等待时间
#define BAHideBarIntervalTime 3

@implementation BAVideoPlayer
{
    AVPlayerLayer            *_playerLayer;        //播放器layer
    id                        _playerTimeObserver;
    
    UIView                   *_bufferView;         //缓冲view
    UIActivityIndicatorView  *_activityView;       //缓冲旋转菊花
    UILabel                  *_bufferLabel;        //缓冲label
    
    UISlider                 *_volumeSlider;       //音量slider
    
    NSTimer                  *_timer;              //计时器
    
    NSString                 *_urlStr;             //视频地址
    
    BOOL                      _haveOriginalUI;     //是否创建默认交互UI
    CGRect                    _initFrame;
    
    CGFloat                   _lastShowBarTime;    //最后一次导航栏显示时的时间
    BOOL                      _isShowBar;          //导航栏是否显示
    
    UIView                   *_topBar;             //顶部导航栏
    UIButton                 *_backButton;         //返回button
    UILabel                  *_titleLabel;         //标题
    
    UIView                   *_footBar;            //底部导航栏
    UIButton                 *_playButton;         //播放\暂停button
    UIButton                 *_switchButton;       //切换全屏button
    UILabel                  *_timeLabel;          //时间label
    
    UISlider                 *_slider;             //播放进度条
    BOOL                      _dragSlider;         //是否正在拖动slider
    UIProgressView           *_progressView;       //缓冲进度条
}

#pragma mark - ***** 初始化
- (instancetype)initWithFrame:(CGRect)frame url:(NSString *)url delegate:(id <BAVideoPlayerDelegate>)delegate haveOriginalUI:(BOOL)haveOriginalUI
{
    if (self=[super initWithFrame:frame])
    {
        _initFrame       = frame;
        _urlStr          = url;
        _delegate        = delegate;
        _currentTime     = 0;
        _totalTime       = 0;
        _isFullScreen    = NO;
        _isSwitch        = NO;
        _changeBar       = NO;
        _lastShowBarTime = 0;
        _haveOriginalUI  = haveOriginalUI;
        _dragSlider      = NO;
        
        // 添加手势
        [self addGR];

        [self createUI];
        
        // 监控播放器
        [_player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
        
        // 开始播放
        [self checkAndUpdateStatus:BAVideoPlayerReadyPlay];
        [_player play];
    }
    return self;
}

#pragma mark - ***** dealloc
- (void)dealloc
{
    [_player removeObserver:self forKeyPath:@"rate"];

    [self closePlayer];
    
    if (self.superview)
    {
        [self removeFromSuperview];
    }
}

#pragma mark - ***** 添加手势
- (void)addGR
{
    // 单击
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGR:)];
    [self addGestureRecognizer:tapGR];
    
    // 双击
    UITapGestureRecognizer *doubleGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGR:)];
    doubleGR.numberOfTouchesRequired = 1;
    doubleGR.numberOfTapsRequired = 2;
    [tapGR requireGestureRecognizerToFail:doubleGR];
    [self addGestureRecognizer:doubleGR];
    
    // 拖动
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self addGestureRecognizer:panGesture];
}

#pragma mark - ***** 关闭播放器
- (void)closePlayer
{
    if (_timer)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    [self removeObserver];
    [self removeNotification];
    
    [_player.currentItem cancelPendingSeeks];
    [_player.currentItem.asset cancelLoading];
    
    [_player removeTimeObserver:_playerTimeObserver];
    _playerTimeObserver = nil;
    
    [_player cancelPendingPrerolls];

    [_player replaceCurrentItemWithPlayerItem:nil];
    
    for (UIView *view in self.subviews)
    {
        [view removeFromSuperview];
    }
    
    for (CALayer *subLayer in self.layer.sublayers)
    {
        [subLayer removeFromSuperlayer];
    }
}

#pragma mark - ***** 计时器
- (void)timeGo
{
    // 判断是否隐藏导航栏
    if ([[NSDate date] timeIntervalSince1970]-_lastShowBarTime>=BAHideBarIntervalTime)
    {
        [self hideNaviBar];
    }
    else if(_lastShowBarTime==0)
    {
        [self hideNaviBar];
    }
    
    if (_slider)
    {
        _slider.userInteractionEnabled=(_totalTime==0)?NO:YES;
    }
}

#pragma mark - ***** 通知
#pragma mark 添加通知
- (void)addNotification
{
    // 添加AVPlayerItem播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    
    // 添加AVPlayerItem开始缓冲通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bufferStart:) name:AVPlayerItemPlaybackStalledNotification object:_player.currentItem];
}

#pragma mark 移除通知
- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark 播放结束通知回调
-(void)playBackFinished:(NSNotification *)notification
{
    [self checkAndUpdateStatus:BAVideoPlayerEnd];
    
    if ([_delegate respondsToSelector:@selector(playFinishedWithItem:)]) {
        [_delegate playFinishedWithItem:notification.object];
    }
}
#pragma mark 缓冲开始回调
- (void)bufferStart:(NSNotification *)notification
{
    [self checkAndUpdateStatus:BAVideoPlayerBuffer];
}

#pragma mark - ***** KVO监控
#pragma mark 给播放器添加进度更新
- (void)addProgressObserver
{
    // 设置每秒执行一次
    AVPlayerItem *playerItem = _player.currentItem;
    __weak typeof (self) weakSelf = self;
    __weak typeof(_slider) weakSlider = _slider;
    
    _playerTimeObserver=[_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0,1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time)
    {
        CGFloat current=CMTimeGetSeconds(time);
        CGFloat total=CMTimeGetSeconds([playerItem duration]);
        
        if (current)
        {
            _currentTime = current;
            _totalTime = total;
            
            if (_haveOriginalUI == YES && weakSlider && _dragSlider == NO)
            {
                weakSlider.value = _currentTime/_totalTime;
                
                [weakSelf updateTime:current];
            }
            if ([weakSelf.delegate respondsToSelector:@selector(updateProgressWithCurrentTime:totalTime:)])
            {
                [weakSelf.delegate updateProgressWithCurrentTime:current totalTime:total];
            }
        }
    }];
}

#pragma mark 添加KVO监控
- (void)addObserver
{
    AVPlayerItem *playerItem = _player.currentItem;
    
    // 监控状态属性(AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态)
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    // 监控是否可播放
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}
#pragma mark 移除KVO监控
- (void)removeObserver
{
    [_player.currentItem removeObserver:self forKeyPath:@"status"];
    [_player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

#pragma mark 通过KVO监控回调
/*! keyPath 监控属性 object 监视器 change 状态改变 context 上下文 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
    {
        //监控是否可播放
        if (_haveOriginalUI==YES&&_bufferView)
        {
            [self removeBufferView];
        }
        
        if (_status!=BAVideoPlayerPause&&_status!=BAVideoPlayerEnd)
        {
            if (_player.currentItem.playbackLikelyToKeepUp==YES)
            {
                [self checkAndUpdateStatus:BAVideoPlayerPlay];
                [_player play];
            }
        }
    }
    else if ([keyPath isEqualToString:@"rate"])
    {
        // 监控播放器播放速率
        if(_player.rate == 1)
        {
            [self checkAndUpdateStatus:BAVideoPlayerPlay];
        }
    }
    else if ([keyPath isEqualToString:@"status"])
    {
        // 监控状态属性
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        
        switch (status)
        {
            case AVPlayerStatusReadyToPlay:
            {
                _currentTime=CMTimeGetSeconds(_player.currentTime);
                _totalTime=CMTimeGetSeconds([_player.currentItem duration]);
                
                if (status!=BAVideoPlayerPause)
                {
                    [self checkAndUpdateStatus:BAVideoPlayerReadyPlay];
                }
            }
                break;
            case AVPlayerStatusUnknown:
            {
                [self closePlayer];
                [self checkAndUpdateStatus:BAVideoPlayerUnknown];
            }
                break;
            case AVPlayerStatusFailed:
            {
                [self closePlayer];
                [self checkAndUpdateStatus:BAVideoPlayerFailed];
            }
                break;
        }
    }
    else if([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        // 监控网络加载情况属性
        NSArray *array=_player.currentItem.loadedTimeRanges;
        
        // 本次缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        
        // 现有缓冲总长度
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        
        if (_haveOriginalUI&&_progressView)
        {
            [_progressView setProgress:totalBuffer/_totalTime animated:NO];
        }
        if ([_delegate respondsToSelector:@selector(updateBufferWithStartTime:duration:totalBuffer:)])
        {
            [_delegate updateBufferWithStartTime:startSeconds duration:durationSeconds totalBuffer:totalBuffer];
        }
    }
}

#pragma mark - ***** 创建UI
- (void)createUI
{
    // 容器view
    self.backgroundColor=[UIColor blackColor];
    self.userInteractionEnabled = YES;
    
    // 播放器
    [self createPlayerWithContainView:self];
    
    // 音量
    MPVolumeView *mpVolumeView=[[MPVolumeView alloc] initWithFrame:CGRectMake(50,50,40,40)];
    for (UIView *view in [mpVolumeView subviews])
    {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"])
        {
            _volumeSlider=(UISlider*)view;
            break;
        }
    }
    [mpVolumeView setHidden:YES];
    [mpVolumeView setShowsVolumeSlider:YES];
    [mpVolumeView sizeToFit];
}

#pragma mark 创建播放器
- (void)createPlayerWithContainView:(UIView *)containView
{
    AVPlayerItem *playerItem = [self getPlayItemWithUrl:_urlStr];
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = containView.bounds;
    
    // 视频填充模式
//    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [containView.layer insertSublayer:_playerLayer atIndex:0];
    
    //默认交互UI
    if (_haveOriginalUI == YES)
    {
        [self createTopBar];
        [self createFootBar];
        [self createBufferView];
    }
    
    // 添加KVO监控
    [self addObserver];
    
    // 进度监控
    [self addProgressObserver];
    
    // 添加通知
    [self addNotification];
    
    // 计时器
    if (_timer==nil)
    {
        _timer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timeGo) userInfo:nil repeats:YES];
    }
    
}
#pragma mark 根据url获得AVPlayerItem对象
- (AVPlayerItem *)getPlayItemWithUrl:(NSString *)urlStr
{
    // 对url进行编码
    //    urlStr =[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    return playerItem;
}
#pragma mark 创建缓冲view
- (void)createBufferView
{
    _bufferView = [[UIView alloc] initWithFrame:CGRectMake(_initFrame.size.width/2-60,_initFrame.size.height/2-30,120,60)];
    _bufferView.backgroundColor = [UIColor blackColor];
    _bufferView.alpha = 0.7;
    _bufferView.layer.cornerRadius = 10;
    _bufferView.layer.masksToBounds = YES;
    
    // 缓冲旋转菊花
     _activityView = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(_bufferView.frame.origin.x+41,_bufferView.frame.origin.y+1,38,38)];
    [_activityView stopAnimating];
    
    // 缓冲label
    _bufferLabel = [[UILabel alloc] initWithFrame:CGRectMake(_bufferView.frame.origin.x,CGRectGetMaxY(_activityView.frame),120,20)];
    _bufferLabel.textColor = [UIColor whiteColor];
    _bufferLabel.textAlignment = NSTextAlignmentCenter;
    _bufferLabel.font = [UIFont systemFontOfSize:16];
    _bufferLabel.text = @"加 载 中...";
}

#pragma mark 创建topBar
- (void)createTopBar
{
    if (_topBar == nil)
    {
        _topBar = [[UIView alloc] initWithFrame:CGRectMake(0,0,_initFrame.size.width,BATOPHEIGHT(NO))];
        _topBar.backgroundColor = [UIColor blackColor];
        _topBar.alpha = 0.5;
        _topBar.userInteractionEnabled = YES;
        [self addSubview:_topBar];
        
        // 返回
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backButton.frame = CGRectMake(5,_topBar.frame.origin.y+BATOPHEIGHT(NO)/2-BAButtonHeight/2,BAButtonWidth,BAButtonHeight);
        _backButton.showsTouchWhenHighlighted = YES;
        [_backButton addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
        [_backButton setImage:[UIImage imageNamed:BA_VideoSrcName(@"返回")] ?: [UIImage imageNamed:BA_VideoFrameworkSrcName(@"返回")] forState:UIControlStateNormal];
        [_backButton setImage:[UIImage imageNamed:BA_VideoSrcName(@"返回")] ?: [UIImage imageNamed:BA_VideoFrameworkSrcName(@"返回")] forState:UIControlStateSelected];
        [self addSubview:_backButton];
        
//        // 标题
//        _titleLabel=[[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxY(_backButton.frame),_topBar.frame.origin.y,_topBar.frame.size.width-CGRectGetMaxY(_backButton.frame)-5,BATOPHEIGHT(NO))];
//        _titleLabel.textColor=[UIColor whiteColor];
//        _titleLabel.font=[UIFont systemFontOfSize:14];
//        [self addSubview:_titleLabel];
    }
}
#pragma mark 创建footBar
- (void)createFootBar
{
    if (_footBar == nil)
    {
        _footBar = [[UIView alloc] initWithFrame:CGRectMake(0,_initFrame.size.height-BAFOOTHEIGHT,_initFrame.size.width,BAFOOTHEIGHT)];
        _footBar.backgroundColor = [UIColor blackColor];
        _footBar.alpha = 0.5;
        _footBar.userInteractionEnabled=YES;
        [self addSubview:_footBar];
        
        // 播放\暂停
        _playButton = [[UIButton alloc] initWithFrame:CGRectMake(5,_footBar.frame.origin.y+BAFOOTHEIGHT/2-BAButtonHeight/2,BAButtonWidth,BAButtonHeight)];
        _playButton.showsTouchWhenHighlighted = YES;
        [_playButton addTarget:self action:@selector(playOrPause) forControlEvents:UIControlEventTouchUpInside];
        [_playButton setImage:[UIImage imageNamed:BA_VideoSrcName(@"play")] ?: [UIImage imageNamed:BA_VideoFrameworkSrcName(@"play")] forState:UIControlStateNormal];
        [_playButton setImage:[UIImage imageNamed:BA_VideoSrcName(@"pause")] ?: [UIImage imageNamed:BA_VideoFrameworkSrcName(@"pause")] forState:UIControlStateSelected];
        [self addSubview:_playButton];
        
        // 切换全屏
        _switchButton = [[UIButton alloc] initWithFrame:CGRectMake(_footBar.frame.size.width-35,_footBar.frame.origin.y+BAFOOTHEIGHT/2-BAButtonHeight/2,BAButtonWidth,BAButtonHeight)];
        _switchButton.showsTouchWhenHighlighted = YES;
        [_switchButton addTarget:self action:@selector(switchClick) forControlEvents:UIControlEventTouchUpInside];
        [_switchButton setImage:[UIImage imageNamed:BA_VideoSrcName(@"fullscreen")] ?: [UIImage imageNamed:BA_VideoFrameworkSrcName(@"fullscreen")] forState:UIControlStateNormal];
        [_switchButton setImage:[UIImage imageNamed:BA_VideoSrcName(@"nonfullscreen")] ?: [UIImage imageNamed:BA_VideoFrameworkSrcName(@"nonfullscreen")] forState:UIControlStateSelected];
        [self addSubview:_switchButton];
        
        // 时间
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_switchButton.frame.origin.x-80,_footBar.frame.origin.y,80,BAFOOTHEIGHT)];
        _timeLabel.textAlignment=NSTextAlignmentCenter;
        _timeLabel.text = @"00:00/00:00";
        _timeLabel.font = [UIFont systemFontOfSize:10];
        _timeLabel.numberOfLines = 0;
        _timeLabel.textColor = [UIColor whiteColor];
        [self addSubview:_timeLabel];
        
        // 缓冲进度条
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.frame = CGRectMake(CGRectGetMaxX(_playButton.frame),_footBar.frame.origin.y+BAFOOTHEIGHT/2,CGRectGetMinX(_timeLabel.frame)-CGRectGetMaxX(_playButton.frame),2);
        _progressView.progressTintColor = [UIColor lightGrayColor];
        _progressView.trackTintColor = [UIColor darkGrayColor];
        [self insertSubview:_progressView belowSubview:_playButton];
        
        // 进度条
        _slider = [[UISlider alloc] initWithFrame:CGRectMake(_progressView.frame.origin.x-2,_progressView.frame.origin.y-14,_progressView.bounds.size.width+2,30)];
        [_slider setThumbImage:[UIImage imageNamed:BA_VideoSrcName(@"dot")] ?: [UIImage imageNamed:BA_VideoFrameworkSrcName(@"dot")] forState:UIControlStateNormal];
        _slider.minimumTrackTintColor = [UIColor whiteColor];
        _slider.maximumTrackTintColor = [UIColor clearColor];
        [_slider addTarget:self action:@selector(sliderChange) forControlEvents:UIControlEventValueChanged];
        [_slider addTarget:self action:@selector(sliderChangeEnd) forControlEvents:UIControlEventTouchUpInside];
        [self insertSubview:_slider aboveSubview:_progressView];
    }
}

#pragma mark - ***** BAVideoPlayer外部交互
#pragma mark 播放
- (void)play
{
    //记录最后一次显示开始时间
    _lastShowBarTime=[[NSDate date] timeIntervalSince1970];
    
    if (_player.currentItem == nil)
    {
        _currentTime = 0;
        _totalTime = 0;
        [self createPlayerWithContainView:self];
    }
    [_player play];
    [self checkAndUpdateStatus:BAVideoPlayerPlay];
}

#pragma mark 暂停
- (void)pause
{
    //记录最后一次显示开始时间
    _lastShowBarTime=[[NSDate date] timeIntervalSince1970];
    
    [_player pause];
    [self checkAndUpdateStatus:BAVideoPlayerPause];
}

#pragma mark 关闭播放器并销毁当前播放view
- (void)close
{
    [self closePlayer];
    for (UIGestureRecognizer *gr in self.gestureRecognizers)
    {
        [self removeGestureRecognizer:gr];
    }
    if (self.superview)
    {
        [self removeFromSuperview];
    }
}

#pragma mark 切换\取消全屏状态
- (void)setIsFullScreen:(BOOL)isFullScreen
{
    // 记录最后一次显示开始时间
    _lastShowBarTime = [[NSDate date] timeIntervalSince1970];
    
    if (_isSwitch == YES)
    {
        return;
    }
    _isFullScreen = isFullScreen;
    
    _isSwitch = YES;
    if (_isFullScreen == YES)
    {
        // 全屏
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];

        [UIView animateWithDuration:0.3 animations:^{
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
            [self updateFrame];
        }completion:^(BOOL finished) {
            _isSwitch = NO;
        }];
    }
    else
    {
        // 非全屏
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];

        [UIView animateWithDuration:0.3 animations:^{
            self.transform = CGAffineTransformIdentity;
            [self updateFrame];
        }completion:^(BOOL finished) {
            _isSwitch = NO;
        }];
    }
}

#pragma mark 改变当前播放时间到time
- (void)seeTime:(CGFloat)time
{
    [_player seekToTime:CMTimeMakeWithSeconds(time,1) completionHandler:^(BOOL finished)
    {
        
    }];
}

#pragma mark - ***** 更新
#pragma mark 检查并更新播放器状态
- (void)checkAndUpdateStatus:(BAVideoPlayerStatus)newStatus
{
    if (_status!=newStatus)
    {
        _status=newStatus;
        
        // 判断进行默认UI交互
        if (_haveOriginalUI==YES)
        {
            switch (_status)
            {
                case BAVideoPlayerReadyPlay:
                {
                    // 可播放
                    [self removeBufferView];
                }
                    break;
                case BAVideoPlayerPlay:
                {
                    // 开始播放
                    _playButton.selected = YES;
                    [self removeBufferView];
                }
                    break;
                case BAVideoPlayerPause:
                {
                    // 暂停
                    _playButton.selected = NO;
                }
                    break;
                case BAVideoPlayerBuffer:
                {
                    // 缓冲
                    _playButton.selected = YES;
                    [self showBufferView];
                }
                    break;
                case BAVideoPlayerEnd:
                {
                    // 播放结束
                    _playButton.selected = NO;
                    [self removeBufferView];
                }
                    break;
                case BAVideoPlayerUnknown:
                {
                    // 播放失败
                    _playButton.selected = NO;
                    [self removeBufferView];
                }
                    break;
                case BAVideoPlayerFailed:
                {
                    // 未知
                    _playButton.selected = NO;
                    [self removeBufferView];
                }
                    break;
            }
        }
        
        if ([_delegate respondsToSelector:@selector(updatePlayerStatus:)])
        {
            [_delegate updatePlayerStatus:_status];
        }
    }
}

#pragma mark - ***** 更新播放器frame
- (void)updateFrame
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    if (_isFullScreen == YES)
    {
        // 全屏
        NSInteger systemVersion = [[UIDevice currentDevice].systemVersion integerValue];
//        self.frame = (systemVersion<8.0&&systemVersion>=7.0) ? CGRectMake(0,0,BA_SCREEN_WIDTH,BA_SCREEN_HEIGHT):CGRectMake(0,0,BA_SCREEN_HEIGHT,BA_SCREEN_WIDTH);

        self.frame = (systemVersion >= 7.0) ? CGRectMake(0,0,BA_SCREEN_WIDTH,BA_SCREEN_HEIGHT):CGRectMake(0,0,BA_SCREEN_HEIGHT,BA_SCREEN_WIDTH);
        _playerLayer.frame = self.bounds;
        self.center = self.window.center;
        
        if (_haveOriginalUI == YES && _topBar && _footBar)
        {
            [self restoreOrChangeAlpha:YES];
            
            [self restoreOrChangeFrame:NO];
            
            _switchButton.selected=YES;
        }
    }
    else
    {
        // 非全屏
        self.frame = _initFrame;
        _playerLayer.frame = self.bounds;
        
        if (_haveOriginalUI == YES && _topBar && _footBar)
        {
            [self restoreOrChangeTransForm:YES];
            
            [self restoreOrChangeFrame:YES];
            
            _switchButton.selected = NO;
        }
    }
}

#pragma mark - ***** 手势点击
#pragma mark 单双击
- (void)tapGR:(UITapGestureRecognizer *)tapGR
{
    if(tapGR.numberOfTapsRequired == 2)
    {
        // 双击
        if ([_delegate respondsToSelector:@selector(doubleClick)])
        {
            [_delegate doubleClick];
        }
        if (_haveOriginalUI == YES)
        {
            [self switchClick];
        }
    }
    else
    {
        // 单击
        if (_isShowBar == YES)
        {
            [self hideNaviBar];
        }
        else
        {
            [self showNaviBar];
        }
    }
}

#pragma mark 拖动
- (void)panGesture:(UIPanGestureRecognizer *)panGR
{
    if(panGR.numberOfTouches>1)
    {
        return;
    }
    CGPoint translationPoint = [panGR translationInView:self];
    [panGR setTranslation:CGPointZero inView:self];
    
    CGFloat x = translationPoint.x;
    CGFloat y = translationPoint.y;
    
    if ((x==0 && fabs(y)>=5) || fabs(y)/fabs(x)>=3)
    {
        //上下调节音量
        if (_dragSlider==YES)
        {
            return;
        }
        CGFloat ratio = ([[UIDevice currentDevice].model rangeOfString:@"iPad"].location != NSNotFound)?20000.0f:13000.0f;
        CGPoint velocity = [panGR velocityInView:self];
        
        CGFloat nowValue = _volumeSlider.value;
        CGFloat changedValue = 1.0f * (nowValue - velocity.y / ratio);
        if(changedValue < 0)
        {
            changedValue = 0;
        }
        if(changedValue > 1)
        {
            changedValue = 1;
        }
        
        [_volumeSlider setValue:changedValue animated:YES];
        
        [_volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(panGR:)])
        {
            [_delegate panGR:panGR];
        }
        if (_haveOriginalUI == YES)
        {
            //默认UI左右拖动调节进度
            if((y == 0 && fabs(x)>=5) || fabs(x)/fabs(y)>=3)
            {
                if (_totalTime == 0)
                {
                    return;
                }
                if (_player.rate == 1||_status!=BAVideoPlayerPause)
                {
                    [_player pause];
                }
                _dragSlider = YES;
                
                _slider.value=_slider.value+(x/self.bounds.size.width);

                [self seeTime:_slider.value*_totalTime];
                [self updateTime:_slider.value*_totalTime];
            }
            if (panGR.state == UIGestureRecognizerStateEnded)
            {
                // 拖动手势结束
                _dragSlider = NO;
                
                if (_status!=BAVideoPlayerPause)
                {
                    [_player play];
                }
            }
        }
    }
}

#pragma mark - ***** 默认UI交互
#pragma mark 显示缓冲view
- (void)showBufferView
{
    [_activityView startAnimating];
    
    if (_bufferView.superview == nil) {
        [self addSubview:_bufferView];
    }
    if (_activityView.superview == nil) {
        [self addSubview:_activityView];
    }
    if (_bufferLabel.superview == nil) {
        [self addSubview:_bufferLabel];
    }
}

#pragma mark 隐藏缓冲view
- (void)removeBufferView
{
    [_activityView stopAnimating];

    [_bufferView removeFromSuperview];
    [_activityView removeFromSuperview];
    [_bufferLabel removeFromSuperview];
}

#pragma mark 设置标题
- (void)setTitle:(NSString *)title
{
    _title=title;
    if (_titleLabel)
    {
        _titleLabel.text = _title;
    }
}

#pragma mark 返回
- (void)backClick
{
    // 记录最后一次显示开始时间
    _lastShowBarTime = [[NSDate date] timeIntervalSince1970];
    
    if (_isFullScreen == YES)
    {
        // 取消全屏
        [self switchClick];
    }
    else
    {
        // 返回
        if ([_delegate respondsToSelector:@selector(backBtnClick)])
        {
            [_delegate backBtnClick];
        }
    }
}

#pragma mark 播放、暂停
- (void)playOrPause
{
    if(_playButton.selected == NO)
    {
        // 开始播放
        if (_status == BAVideoPlayerEnd)
        {
            [self seeTime:1];
            [self updateTime:1];
        }
        [self play];
        _playButton.selected=YES;
    }
    else
    {
        // 暂停播放
        [self pause];
        _playButton.selected=NO;
    }
}

#pragma mark 切换\取消全屏状态
- (void)switchClick
{
    self.isFullScreen = !_isFullScreen;
    
    if ([_delegate respondsToSelector:@selector(switchFullScreen)])
    {
        [_delegate switchFullScreen];
    }
}

#pragma mark 拖动slider时,改变当前播放时间
- (void)sliderChange
{
    if (_totalTime == 0)
    {
        return;
    }
    _dragSlider = YES;
    
    [self seeTime:_slider.value*_totalTime];
    
    [self updateTime:_slider.value*_totalTime];
}

#pragma mark 拖动slider后
- (void)sliderChangeEnd
{
    _dragSlider = NO;
}

#pragma mark 更新播放时间
- (void)updateTime:(CGFloat)playTime
{
    NSInteger a = playTime/60;
    NSInteger b = _totalTime/60;
    NSInteger c = playTime-a*60;
    NSInteger d = _totalTime-b*60;
    
    if (_timeLabel)
    {
        _timeLabel.text=[NSString stringWithFormat:@"%ld:%02ld/%ld:%02ld",(long)a,(long)c,(long)b,(long)d];
    }
}

#pragma mark 显示导航栏
- (void)showNaviBar
{
    // 记录最后一次显示开始时间
    _lastShowBarTime=[[NSDate date] timeIntervalSince1970];
    if (_isShowBar == YES || _changeBar == YES)
    {
        return;
    }
    _isShowBar = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    if ([_delegate respondsToSelector:@selector(showNaviBar)])
    {
        [_delegate showNaviBar];
    }
    if (_haveOriginalUI == YES && _changeBar == NO)
    {
        _changeBar = YES;
        [UIApplication sharedApplication].statusBarStyle=UIStatusBarStyleLightContent;
        
        [UIView animateWithDuration:0.3 animations:^{
            [self restoreOrChangeAlpha:YES];
            
            [self restoreOrChangeTransForm:YES];
            
        }completion:^(BOOL finished) {
            _changeBar=NO;
        }];
    }
    
}

#pragma mark 隐藏导航栏
- (void)hideNaviBar
{
    if (_isShowBar == NO || _changeBar == YES)
    {
        return;
    }
    _isShowBar = NO;
    if (_isFullScreen == YES)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    if ([_delegate respondsToSelector:@selector(hideNaviBar)])
    {
        [_delegate hideNaviBar];
    }
    if (_haveOriginalUI == YES && _changeBar == NO)
    {
        _changeBar = YES;

        [self restoreOrChangeTransForm:YES];
        
        [UIView animateWithDuration:0.3 animations:^{
            if (_isFullScreen == YES)
            {
                [self restoreOrChangeTransForm:NO];
                
                [self restoreOrChangeAlpha:YES];
            }
            else
            {
                [self restoreOrChangeAlpha:NO];
            }
        }completion:^(BOOL finished) {
            _changeBar = NO;
        }];
    }
}

#pragma mark 恢复或改变transForm
- (void)restoreOrChangeTransForm:(BOOL)restore
{
    CGAffineTransform oriTransform = CGAffineTransformIdentity;
    CGAffineTransform topTransform = CGAffineTransformMakeTranslation(0,-_topBar.bounds.size.height);
    CGAffineTransform footTransform = CGAffineTransformMakeTranslation(0,_footBar.bounds.size.height);
    
    if (restore == YES)
    {
        _topBar.transform = oriTransform;
        _backButton.transform = oriTransform;
        _titleLabel.transform = oriTransform;
        
        _footBar.transform = oriTransform;
        _playButton.transform = oriTransform;
        _switchButton.transform = oriTransform;
        _progressView.transform = oriTransform;
        _slider.transform = oriTransform;
        _timeLabel.transform = oriTransform;
    }
    else
    {
        _topBar.transform = topTransform;
        _backButton.transform = topTransform;
        _titleLabel.transform = topTransform;
        
        _footBar.transform = footTransform;
        _playButton.transform = footTransform;
        _switchButton.transform = footTransform;
        _progressView.transform = footTransform;
        _slider.transform = footTransform;
        _timeLabel.transform = footTransform;
    }
}

#pragma mark - ***** 恢复或改变alpha
- (void)restoreOrChangeAlpha:(BOOL)restore
{
    CGFloat a = 0;
    CGFloat b = 0.5;
    CGFloat c = 1;
    
    if (restore == YES)
    {
        _topBar.alpha = b;
        _backButton.alpha = c;
        _titleLabel.alpha = c;
        
        _footBar.alpha = b;
        _playButton.alpha = c;
        _switchButton.alpha = c;
        _progressView.alpha = c;
        _slider.alpha = c;
        _timeLabel.alpha = c;
    }
    else
    {
        _topBar.alpha = a;
        _backButton.alpha = a;
        _titleLabel.alpha = a;
        
        _footBar.alpha = a;
        _playButton.alpha = a;
        _switchButton.alpha = a;
        _progressView.alpha = a;
        _slider.alpha = a;
        _timeLabel.alpha = a;
    }
}
#pragma mark 恢复或改变frame
- (void)restoreOrChangeFrame:(BOOL)restoreFrame
{
    if (restoreFrame == YES)
    {
        _topBar.frame = CGRectMake(0,0,_initFrame.size.width,BATOPHEIGHT(NO));
        _footBar.frame = CGRectMake(0,_initFrame.size.height-BAFOOTHEIGHT,_initFrame.size.width,BAFOOTHEIGHT);

        _backButton.frame = CGRectMake(5,_topBar.frame.origin.y+BATOPHEIGHT(NO)/2-BAButtonHeight/2,BAButtonWidth,BAButtonHeight);
        _titleLabel.frame = CGRectMake(CGRectGetMaxY(_backButton.frame),_topBar.frame.origin.y,_topBar.frame.size.width-CGRectGetMaxY(_backButton.frame)-5,BATOPHEIGHT(NO));
    }
    else
    {
        _topBar.frame = CGRectMake(0,0,self.bounds.size.width,BATOPHEIGHT(YES));
        _footBar.frame = CGRectMake(0,self.bounds.size.height-BAFOOTHEIGHT,self.bounds.size.width,BAFOOTHEIGHT);
        
        _backButton.frame = CGRectMake(5,_topBar.frame.origin.y+BATOPHEIGHT(NO)/2-BAButtonHeight/2+20,BAButtonWidth,BAButtonHeight);
        _titleLabel.frame = CGRectMake(CGRectGetMaxY(_backButton.frame),_topBar.frame.origin.y+20,_topBar.frame.size.width-CGRectGetMaxY(_backButton.frame)-5,BATOPHEIGHT(NO));
    }
    _bufferView.frame = CGRectMake(self.bounds.size.width/2-60,self.bounds.size.height/2-30,120,60);
    _activityView.frame = CGRectMake(_bufferView.frame.origin.x+41,_bufferView.frame.origin.y+1,38,38);
    _bufferLabel.frame = CGRectMake(_bufferView.frame.origin.x,CGRectGetMaxY(_activityView.frame),120,20);
                  
    _playButton.frame = CGRectMake(5,_footBar.frame.origin.y+BAFOOTHEIGHT/2-BAButtonHeight/2,BAButtonWidth,BAButtonHeight);
    _switchButton.frame = CGRectMake(_footBar.frame.size.width-35,_footBar.frame.origin.y+BAFOOTHEIGHT/2-BAButtonHeight/2,BAButtonWidth,BAButtonHeight);
    _timeLabel.frame = CGRectMake(_switchButton.frame.origin.x-80,_footBar.frame.origin.y,80,BAFOOTHEIGHT);
    _progressView.frame = CGRectMake(CGRectGetMaxX(_playButton.frame),_footBar.frame.origin.y+BAFOOTHEIGHT/2,CGRectGetMinX(_timeLabel.frame)-CGRectGetMaxX(_playButton.frame),2);
    _slider.frame = CGRectMake(_progressView.frame.origin.x-2,_progressView.frame.origin.y-14,_progressView.bounds.size.width+2,30);
}

@end
