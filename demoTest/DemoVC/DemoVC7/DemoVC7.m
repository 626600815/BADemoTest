//
//  DemoVC7.m
//  demoTest
//
//  Created by 博爱 on 16/3/16.
//  Copyright © 2016年 博爱之家. All rights reserved.
//

#import "DemoVC7.h"
#import "DemoVC7Model.h"
#import "DemoVC7Cell.h"

#import "DemoVC7_replyVC.h"

@interface DemoVC7 ()

@property (nonatomic, strong) NSMutableArray *dataArray7;

@end

@implementation DemoVC7

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self creatModelsData7];
}

- (void)creatModelsData7
{
    if (!_dataArray7) {
        _dataArray7 = [NSMutableArray new];
    }
    
    NSArray *iconImageNamesArray = @[@"icon0.jpg",
                                     @"icon1.jpg",
                                     @"icon2.jpg",
                                     @"icon3.jpg",
                                     @"icon4.jpg",
                                     ];
    
    NSArray *namesArray = @[@"博爱",
                            @"小明",
                            @"张三",
                            @"我是小明的老师",
                            @"小三"];
    
    NSArray *textArray = @[@"欢迎使用 iPhone SE，迄今最高性能的 4 英寸 iPhone。在打造这款手机时，我们在深得人心的 4 英寸设计基础上，让它从里到外焕然一新。它所采用的 A9 芯片，正是在 iPhone 6s 上使用的先进芯片。1200 万像素的摄像头能拍出令人叹为观止的精彩照片和 4K 视频，而 Live Photos 则会让你的照片栩栩如生。这一切，成就了一款外形小巧却异常强大的 iPhone。",
                           @"iPhone SE 采用了备受欢迎的设计，并让它更加出色。铝金属表面经过喷砂工艺处理，打造出绸缎般的质感，让这款小巧、轻便的手机握持时手感非常舒适。绚丽的 4 英寸1 Retina 显示屏让图像显得生动、锐利。倒角边缘经过哑光处理，不锈钢 Apple 标志的颜色也与机身相配，整个外观显得格外精致。",
                           @"iPhone SE 的核心是 A9 芯片，它与 iPhone 6s 采用了相同的先进芯片。",
                           @"高能效的M9 运动协处理器M9 运动协处理器直接嵌入在 A9 芯片上，并与加速感应器、指南针及三轴陀螺仪相连，具备一系列追踪健身活动的功能，比如记录你的步数和距离。而且，有了它，你不必拿起 iPhone，只需说一声 “嘿 Siri” 就能轻松激活 Siri。",
                           @"Live Photos 可捕捉声音和动作，让你的影像生动鲜活。只需在你的 1200 万像素照片上按住任意位置，就能重温照片拍摄前后的时刻，让你的照片变成鲜活的记忆。"
                           ];
    
    NSArray *picImageNamesArray = @[ @"1",
                                     @"2",
                                     @"3",
                                     @"4",
                                     @"5",
                                     ];
    
    NSArray *supportNumberArray = @[ @"111",
                                     @"222",
                                     @"3333",
                                     @"444",
                                     @"555",
                                     ];
    NSArray *timeArray = @[@"2016-03-06",@"2016-03-07",@"2016-03-08",@"2016-03-09",@"2016-03-10"];
    
    for (int i = 0; i < 10; i++) {
        int iconRandomIndex = arc4random_uniform(5);
        int nameRandomIndex = arc4random_uniform(5);
        int contentRandomIndex = arc4random_uniform(5);
        int picRandomIndex = arc4random_uniform(5);
        
        DemoVC7Model *model = [DemoVC7Model new];
        model.imageName = iconImageNamesArray[iconRandomIndex];
        model.userName = namesArray[nameRandomIndex];
        model.content = textArray[contentRandomIndex];
        model.time = timeArray[picRandomIndex];
        model.starNumber = picImageNamesArray[picRandomIndex];
        model.supportNumber = supportNumberArray[picRandomIndex];
        
        [self.dataArray7 addObject:model];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArray7.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    DemoVC7Cell *cell7 = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell7)
    {
        cell7 = [[DemoVC7Cell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
    }
    
    cell7.model = self.dataArray7[indexPath.section];
    
    return cell7;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.tableView cellHeightForIndexPath:indexPath model:self.dataArray7[indexPath.section] keyPath:@"model" cellClass:[DemoVC7Cell class] contentViewWidth:[self cellContentViewWith]];
}

- (CGFloat)cellContentViewWith
{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    // 适配ios7
    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait && [[UIDevice currentDevice].systemVersion floatValue] < 8) {
        width = [UIScreen mainScreen].bounds.size.height;
    }
    return width;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 0;
    }
    return 10;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BALog(@"self.dataArray7: %@", self.dataArray7[indexPath.section]);
    
    DemoVC7_replyVC *replyVC = [[DemoVC7_replyVC alloc] init];
    replyVC.quesstionDataModel = self.dataArray7[indexPath.section];
    replyVC.title = [NSString stringWithFormat:@"回复%@的评论", replyVC.quesstionDataModel.userName];
    [self.navigationController pushViewController:replyVC animated:YES];
    
    // 点击立刻取消该cell的选中状态
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



@end
