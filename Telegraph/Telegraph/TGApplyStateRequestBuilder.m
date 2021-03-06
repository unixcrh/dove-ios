#import "TGApplyStateRequestBuilder.h"

#import "ActionStage.h"

#import "TGDatabase.h"

@implementation TGApplyStateRequestBuilder

+ (NSString *)genericPath
{
    return @"/tg/service/applystate/@";
}

- (id)initWithPath:(NSString *)path
{
    self = [super initWithPath:path];
    if (self != nil)
    {   
        self.requestQueueName = @"messages";
        
        self.cancelTimeout = 0;
    }
    return self;
}

- (void)execute:(NSDictionary *)options
{
    int pts = [[options objectForKey:@"pts"] intValue];
    int date = [[options objectForKey:@"date"] intValue];
    int seq = [[options objectForKey:@"seq"] intValue];
    int unreadCount = [[options objectForKey:@"unreadCount"] intValue];
    int qts = [[options objectForKey:@"qts"] intValue];
    
    if (seq != 0)
        TGLog(@"===== seq: %d", seq);
    
    if (qts != 0)
        TGLog(@"===== qts: %d", qts);
    
    int unreadCountForGroup = [TGDatabaseInstance() databaseState].unreadCountForGroup;
    int unreadCountForSingle = [TGDatabaseInstance() databaseState].unreadCountForSingle;
    if (unreadCount != unreadCountForGroup + unreadCountForSingle) {
        NSDictionary *dict = [TGDatabaseInstance() loadChatUnreadCountInfo];
        unreadCountForGroup = [[dict objectForKey:@"countForGroup"] intValue];
        unreadCountForSingle = [[dict objectForKey:@"countForSingle"] intValue];
    }
    [[TGDatabase instance] applyPts:pts date:date seq:seq qts:qts unreadCount:unreadCount unreadCountForGroup:unreadCountForGroup unreadCountForSingle:unreadCountForSingle];
    
    [ActionStageInstance() actionCompleted:self.path result:nil];
}

- (void)cancel
{
    [super cancel];
}

@end
