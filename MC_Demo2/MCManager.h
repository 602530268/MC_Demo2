//
//  MCManager.h
//  MC_Demo2
//
//  Created by double on 2017/5/13.
//  Copyright © 2017年 double. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

typedef NS_ENUM(NSUInteger,MCType) {
    MCTypeNone,
    MCTypeCreate,
    MCTypeJoin,
};

typedef void(^SearchToPeerID)(NSMutableArray *peerIDs);    //搜索到房间
typedef void(^ConnectToPeerID)(MCPeerID *peerID);   //申请连接
typedef void(^ReceiveConnectRequest)(MCPeerID *peerID); //收到加入申请
typedef void(^LostPeerID)(MCPeerID *peerID);    //丢失房间信息
typedef void(^SessionState)(MCSessionState state);  //连接状态

typedef void(^ReceiveData)(NSData *data);   //接收数据
typedef void(^SendResourceProgress)(CGFloat progress);  //发送文件进度
typedef void(^ReceiveResourceProgress)(CGFloat progrsss);   //接收文件进度

@interface MCManager : NSObject

@property(nonatomic,copy) SearchToPeerID searchToPeerID;
@property(nonatomic,copy) ReceiveConnectRequest receiveConnectRequest;
@property(nonatomic,copy) LostPeerID lostPeerID;
@property(nonatomic,copy) SessionState sessionState;
@property(nonatomic,copy) ReceiveData receiveData;
@property(nonatomic,copy) SendResourceProgress sendResourceProgress;
@property(nonatomic,copy) ReceiveResourceProgress receiveResourceProgress;

@property(nonatomic,assign) MCType type;

+ (MCManager *)shareInstance;

- (void)setTypeWith:(MCType)type;   //设置是创建还是加入
- (MCSessionState)getSessionState;  //获取当前连接状态

- (void)create:(ReceiveConnectRequest)receiveConnectRequest;
- (void)search:(SearchToPeerID)searceToPeerID;
- (void)stop;
- (void)connectWithPeerID:(MCPeerID *)peerID;
- (void)handleJoinRequest:(BOOL)agree;
- (void)disconnect;

- (void)sendData:(NSData *)data finish:(void(^)(NSError *error))finish;   //发送数据
- (void)sendResource:(NSString *)filePath resourceName:(NSString *)resourceName sending:(SendResourceProgress)sending finish:(void(^)(NSError *error))finish;    //发送文件
//流数据传输暂不使用

@end
