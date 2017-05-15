//
//  MCManager.m
//  MC_Demo2
//
//  Created by double on 2017/5/13.
//  Copyright © 2017年 double. All rights reserved.
//

#import "MCManager.h"
static NSString * const serviceTypeString = @"mc-service";   //标识符

static MCManager *manager;
@interface MCManager ()<MCSessionDelegate,MCNearbyServiceAdvertiserDelegate,MCNearbyServiceBrowserDelegate>
{
    NSMutableArray *_peerIDs;   //搜索到的房间
    NSProgress *_progress;  //进度管理
    void (^_invitationHandler)(BOOL accept, MCSession * __nullable session);
    MCSessionState _state;
}

@property(nonatomic,strong) MCPeerID *peerID;
@property(nonatomic,strong) MCSession *session;
@property(nonatomic,strong) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property(nonatomic,strong) MCNearbyServiceBrowser *serviceBrowser;

- (void)retset; //重置

@end

@implementation MCManager

#pragma mark - 接口方法
+ (MCManager *)shareInstance {
    if (!manager) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            manager = [[MCManager alloc] init];
        });
    }
    return manager;
}

- (void)setTypeWith:(MCType)type {
    _type = type;
    [self retset];
}

- (MCSessionState)getSessionState {
    return _state;
}

- (void)create:(ReceiveConnectRequest)receiveConnectRequest {
    if (_type != MCTypeCreate) return;
    
    _receiveConnectRequest = receiveConnectRequest;
    [self.serviceAdvertiser startAdvertisingPeer];
}

- (void)search:(SearchToPeerID)searceToPeerID {
    if (_type != MCTypeJoin) return;
    
    _peerIDs = @[].mutableCopy;
    _searchToPeerID = searceToPeerID;
    [self.serviceBrowser startBrowsingForPeers];
}

- (void)stop {
    switch (_type) {
        case MCTypeCreate:
            [self.serviceAdvertiser stopAdvertisingPeer];
            break;
        case MCTypeJoin:
            [self.serviceBrowser stopBrowsingForPeers];
            break;
        default:
            break;
    }
}

- (void)connectWithPeerID:(MCPeerID *)peerID {
    if (_type != MCTypeJoin) return;
    [self.serviceBrowser invitePeer:peerID toSession:self.session withContext:nil timeout:10.0];    //加入时等待主人允许，timeout秒后不答应就退出
}

- (void)handleJoinRequest:(BOOL)agree {
    if (_invitationHandler) {
        _invitationHandler(agree,self.session);
        _invitationHandler = nil;
    }
}

- (void)disconnect {
    if (_state == MCSessionStateConnected) {
        [self.session disconnect];
    }
}

- (void)sendData:(NSData *)data finish:(void(^)(NSError *error))finish {
    NSError *error = nil;
    [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];   //MCSessionSendDataUnreliable
    finish(error);
}

- (void)sendResource:(NSString *)filePath resourceName:(NSString *)resourceName sending:(SendResourceProgress)sending finish:(void(^)(NSError *error))finish {
    _sendResourceProgress = sending;
    NSURL *url = [NSURL fileURLWithPath:filePath];
    
    if (_progress) {
        [_progress removeObserver:self forKeyPath:@"completedUnitCount"];
        _progress = nil;
    }
    
    _progress = [self.session sendResourceAtURL:url withName:resourceName toPeer:self.session.connectedPeers.firstObject withCompletionHandler:^(NSError * _Nullable error) {
        finish(error);
    }];
    //KVO观察
    [_progress addObserver:self forKeyPath:@"completedUnitCount" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if (object == _progress) {
        int64_t numberCom = _progress.completedUnitCount;
        int64_t numberTotal = _progress.totalUnitCount;
        CGFloat progress = (float)numberCom / (float)numberTotal;
        if (_sendResourceProgress) {
            _sendResourceProgress(progress);
        }
        if (_receiveResourceProgress) {
            _receiveResourceProgress(progress);
        }
    }

}

#pragma mark - MCSessionDelegate
//监测连接状态
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    switch (state) {
        case MCSessionStateConnecting:
            NSLog(@"正在连接...");
            break;
        case MCSessionStateConnected:
            NSLog(@"连接成功!");
            [self stop];
            break;
        case MCSessionStateNotConnected:
        default:
            NSLog(@"连接失败~");
            break;
    }
    _state = state;
    if (_sessionState) {
        _sessionState(state);
    }
}

//小数据的接收
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSLog(@"小数据接收");
    if (_receiveData) {
        _receiveData(data);
    }
}

//对流stream的接收
- (void)session:(MCSession *)session
didReceiveStream:(NSInputStream *)stream
       withName:(NSString *)streamName
       fromPeer:(MCPeerID *)peerID {
    NSLog(@"stream 接收");
}

//开始从远程端口接收文件
- (void)session:(MCSession *)session
didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
   withProgress:(NSProgress *)progress {
    NSLog(@"文件 接收...");
    
    if (_progress) {
        [_progress removeObserver:self forKeyPath:@"completedUnitCount"];
        _progress = nil;
    }
    _progress = progress;
    //KVO观察
    [_progress addObserver:self forKeyPath:@"completedUnitCount" options:NSKeyValueObservingOptionNew context:nil];
}

//接收文件完成
- (void)session:(MCSession *)session
didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
          atURL:(NSURL *)localURL
      withError:(nullable NSError *)error {
    NSLog(@"文件接收完成!");
}

#pragma mark - MCNearbyServiceAdvertiserDelegate
//收到加入请求
- (void)            advertiser:(MCNearbyServiceAdvertiser *)advertiser
  didReceiveInvitationFromPeer:(MCPeerID *)peerID
                   withContext:(nullable NSData *)context
             invitationHandler:(void (^)(BOOL accept, MCSession * __nullable session))invitationHandler {
    NSLog(@"收到加入请求");
    
    _invitationHandler = invitationHandler;
    if (_receiveConnectRequest) {
        _receiveConnectRequest(peerID);
    }
    
}

//连接错误时
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"didNotStartAdvertisingPeer error = %@",error);
    _sessionState(MCSessionStateNotConnected);
}

#pragma mark - MCNearbyServiceBrowserDelegate
//搜索到房间
- (void)browser:(MCNearbyServiceBrowser *)browser
      foundPeer:(MCPeerID *)peerID
withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info {
    NSLog(@"搜索到的设备名 %@",peerID.displayName);
    if (![_peerIDs containsObject:peerID]) {
        [_peerIDs addObject:peerID];
        
        if (_searchToPeerID) {
            _searchToPeerID(_peerIDs);
        }
    }
}

//丢失房间信息
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"丢失房间信息 %@",peerID);
    if (_lostPeerID) {
        _lostPeerID(peerID);
    }
}

//连接错误
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"连接错误");
}

#pragma mark - 私有方法
- (void)retset {
    //置空
    if (_session) {
        [_session disconnect];
        _session = nil;
    }
    if (_serviceAdvertiser) {
        [_serviceAdvertiser stopAdvertisingPeer];
        _serviceAdvertiser = nil;
    }
    if (_serviceBrowser) {
        [_serviceBrowser stopBrowsingForPeers];
        _serviceBrowser = nil;
    }
    _peerIDs = @[].mutableCopy;
}

#pragma mark - 懒加载
- (MCPeerID *)peerID {
    if (!_peerID) {
        _peerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    }
    return _peerID;
}

- (MCSession *)session {
    if (!_session) {
        _session = [[MCSession alloc] initWithPeer:self.peerID];
        _session.delegate = self;
    }
    return _session;
}

- (MCNearbyServiceAdvertiser *)serviceAdvertiser {
    if (!_serviceAdvertiser) {
        _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:serviceTypeString];
        _serviceAdvertiser.delegate = self;
    }
    return _serviceAdvertiser;
}

- (MCNearbyServiceBrowser *)serviceBrowser {
    if (!_serviceBrowser) {
        _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:serviceTypeString];
        _serviceBrowser.delegate = self;
    }
    return _serviceBrowser;
}


@end
